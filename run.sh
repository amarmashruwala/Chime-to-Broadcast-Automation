#!/bin/bash
BROWSER_URL=${MEETING_URL}
SCREEN_WIDTH=1920
SCREEN_HEIGHT=1080
SCREEN_RESOLUTION=${SCREEN_WIDTH}x${SCREEN_HEIGHT}
CAPTURE_SCREEN_RESOLUTION=1920x1080
COLOR_DEPTH=24
X_SERVER_NUM=2
VIDEO_BITRATE=6000
VIDEO_FRAMERATE=30
VIDEO_GOP=$((VIDEO_FRAMERATE * 2))
AUDIO_BITRATE=160k
AUDIO_SAMPLERATE=44100
AUDIO_CHANNELS=2

# Start PulseAudio server so Firefox will have somewhere to which to send audio
pulseaudio -D --exit-idle-time=-1
pacmd load-module module-virtual-sink sink_name=v1  # Load a virtual sink as `v1`
pacmd set-default-sink v1  # Set the `v1` as the default sink device
pacmd set-default-source v1.monitor  # Set the monitor of the v1 sink to be the default source

# Start X11 virtual framebuffer so Firefox will have somewhere to draw
Xvfb :${X_SERVER_NUM} -ac -screen 0 ${SCREEN_RESOLUTION}x${COLOR_DEPTH} > /dev/null 2>&1 &
export DISPLAY=:${X_SERVER_NUM}.0
sleep 0.5  # Ensure this has started before moving on

# Create a new Firefox profile for capturing preferences for this
firefox --no-remote --new-instance --createprofile "foo4 /tmp/foo4"

# Install the OpenH264 plugin for Firefox
mkdir -p /tmp/foo4/gmp-gmpopenh264/1.8.1.1/
pushd /tmp/foo4/gmp-gmpopenh264/1.8.1.1 >& /dev/null
curl -s -O http://ciscobinary.openh264.org/openh264-linux64-2e1774ab6dc6c43debb0b5b628bdf122a391d521.zip
unzip openh264-linux64-2e1774ab6dc6c43debb0b5b628bdf122a391d521.zip
rm -f openh264-linux64-2e1774ab6dc6c43debb0b5b628bdf122a391d521.zip
popd >& /dev/null

# Set the Firefox preferences to enable automatic media playing with no user
# interaction and the use of the OpenH264 plugin.
cat <<EOF >> /tmp/foo4/prefs.js
user_pref("media.autoplay.default", 0);
user_pref("media.autoplay.enabled.user-gestures-needed", false);
user_pref("media.navigator.permission.disabled", true);
user_pref("media.gmp-gmpopenh264.abi", "x86_64-gcc3");
user_pref("media.gmp-gmpopenh264.lastUpdate", 1571534329);
user_pref("media.gmp-gmpopenh264.version", "1.8.1.1");
user_pref("doh-rollout.doorhanger-shown", true);
EOF

# Start Firefox browser and point it at the URL we want to capture
#
# NB: The `--width` and `--height` arguments have to be very early in the
# argument list or else only a white screen will result in the capture for some
# reason.
firefox \
  -P foo4 \
  --width ${SCREEN_WIDTH} \
  --height ${SCREEN_HEIGHT} \
  --new-instance \
  --first-startup \
  --foreground \
  --kiosk \
  --ssb \
  "${BROWSER_URL}" \
  &
sleep 10  # Ensure this has started before moving on, waiting for loading the Chime web app
id=$(xdotool search --onlyvisible --name Firefox)
xdotool windowfocus --sync $id
xdotool key Return #Select yes for the pop-up window of "Would you like to open this link with Chime app?"
sleep 3
xdotool key Escape #Close the pop-up window
sleep 5
xdotool type Livestream #Type "Livestream" on the name input field
sleep 5
xdotool key Tab #Move to "join the meeting" button
sleep 3
xdotool key Return #Click "join the meeting" button
sleep 5
xdotool key Return #Close the pop-up window once again
sleep 3
xdotool key Escape #Close the pop-up window once again
sleep 5
xdotool key Return #Click "Use system audio" setting
sleep 5
xdotool key Escape #Close warning message
sleep 3
xdotool mousemove 1 1 click 1  # Move mouse out of the way so it doesn't trigger the "pause" overlay on the video tile  

# Start ffmpeg to transcode the capture from the X11 framebuffer and the
# PulseAudio virtual sound device we created earlier and send that to the RTMP
# endpoint in H.264/AAC format using a FLV container format.
#
# NB: These arguments have a very specific order. Seemingly inocuous changes in
# argument order can have pretty drastic effects, so be careful when
# adding/removing/reordering arguments here.
ffmpeg \
  -hide_banner -loglevel error \
  -nostdin \
  -s ${CAPTURE_SCREEN_RESOLUTION} \
  -r ${VIDEO_FRAMERATE} \
  -draw_mouse 0 \
  -f x11grab \
    -i ${DISPLAY} \
  -f pulse \
    -ac 2 \
    -i default \
    -vf "crop=1600:980:0:1080,scale=1920:-1" \
  -c:v libx264 \
    -pix_fmt yuv420p \
    -profile:v high \
    -preset superfast \
    -tune zerolatency \
    -x264opts "nal-hrd=cbr:no-scenecut" \
    -minrate ${VIDEO_BITRATE} \
    -maxrate ${VIDEO_BITRATE} \
    -g ${VIDEO_GOP} \
  -filter_complex "aresample=async=1000:min_hard_comp=0.100000:first_pts=1" \
  -async 1 \
  -c:a aac \
    -b:a ${AUDIO_BITRATE} \
    -ac ${AUDIO_CHANNELS} \
    -ar ${AUDIO_SAMPLERATE} \
  -f flv ${RTMP_URL}
