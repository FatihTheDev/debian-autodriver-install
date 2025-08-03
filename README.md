# debian-autodriver-install
---
This is a shell script to automatically install GPU drivers and hardware acceleration drivers from backports on a clean Debian install.

Steps to run the script:
```
sudo apt install -y git
git clone https://github.com/FatihTheDev/debian-autodriver-install.git ~/.setup
bash install.sh $(lsb_release -cs)
```
