To run Animus on Windows:
- Make sure you have Java installed
- Choose either 32 or 64-bit version based on your Windows version and run Animus.exe
- If all goes well it'll run fullscreen and you can quit by pressing 'e' on your keyboard.

To enable sound:

- Install SuperCollider from here: http://supercollider.sourceforge.net/downloads/
- If you're on Windows, run scide.exe from C:\Program Files (x86)\SuperCollider-3.6.3 (or your install location) and make sure you give it permission to access private/public networks when asked.
- Copy and paste the code from grains.sc (which opens with notepad) in the editor on the left.
- Locate "Server" on bottom right of the window, right-click and select Boot Server.
- Now select the code in the editor and press Ctrl + Enter to run. If all goes well you'll see "a synthdef" appear in the window above Server.
- You can now run Animus and it'll start with sound enabled. Make sure your speakers are NOT turned all the way up since it starts out pretty loud. 
- You must quit the program by pressing 'e' to stop audio when it quits. If the audio keeps running even after you quit Animus (which can be annoying), you can stop it by clicking Ctrl + '.' (period) inside Supercollider or by closing Supercollider.