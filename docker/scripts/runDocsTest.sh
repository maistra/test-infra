set -e
git clone https://github.com/Maistra/maistra.github.io.git > /dev/null
cd maistra.github.io
hugo serve >/dev/null &
muffet -e .nip.io -e GATEWAY_URL http://localhost:1313
killall hugo

