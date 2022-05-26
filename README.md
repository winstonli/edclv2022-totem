# EDC LV 2022 Totem!

https://user-images.githubusercontent.com/3519080/169437440-1fbe31d7-beb8-42d3-9f2c-f1eeb00bd1d4.mp4

## Quick Start (Simulators)

You can run the Totem and the iOS app on their respective Simulators.

### Requirements

- Rust (install: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- Xcode
- macOS (Intel, Big Sur. Apple Silicon support done in theory but unverified as I don't have one and
am waiting for M2)

### Steps

1. `./build-and-run.sh`

This will:
- download dependencies / fetch submodules
- compile `totem` (the totem program), `totem-bridge` (native library for iOS), the iOS app, and
[Doom](#Doom)
- run the Totem and the iOS app on their respective simulators

https://user-images.githubusercontent.com/3519080/169437499-e1bf3784-310c-4cd4-8fc3-7ed52bbfa8d5.mp4

## Quick Start (Totem Hardware)

TODO

Apologies that there is little documentation since I didn't have many weekends to work on this. Here are some implementation notes:

## Notes

### `totem` program

"Totem OS" (it's not really an OS btw) is a Rust program running on the Totem.

- On the real Totem (an `aarch64-unknown-linux-gnu` platform), it uses a 128x96 display made of 6
LED panels, and its onboard Wi-Fi.
- On my machine (`x86_64-apple-darwin`) (and hopefully `aarch64-apple-darwin`), it uses a 128x96
Display Simulator with regular graphics and networking.

#### Display Driver

Each platform has a display "driver":
- On the simulator: SDL.
- On the totem: [rpi-rgb-led-matrix](https://github.com/hzeller/rpi-rgb-led-matrix),
which writes the frame buffer to Raspberry Pi GPIO pins memory-mapped in user-space.

#### Cross-Compilation (real hardware only)

Compiling the C++ [rpi-rgb-led-matrix](https://github.com/hzeller/rpi-rgb-led-matrix) library and Rust program on the totem itself takes 20-30min
using its own toolchain. It's not practical to develop like this.

Instead, we cross-compile the "driver" using the totem's C++ toolchain (`aarch64-unknown-linux-gnu`)
built for my machine (`x86_64-apple-darwin`). It had to be GCC 10 because it depends on
`libstdc++.so` and the platform provides the one from GCC 10. While this was painful to set up, it
paid for itself many times over.

Next, the Rust program is compiled using a Rust `aarch64-unknown-linux-gnu` toolchain. Switching
Rust toolchains is easy due to LLVM. You just need the target platform's linker (taken from above).

After this, it's easy to develop locally on the simulators and then cross-compile & `scp` the
executable to the real totem. This leads to better programs with the same amount of effort (or the
same programs with less effort).

Doom was also cross-compiled on my machine because we already had the C compiler from the toolchain
so why not.

### iOS App

The core non-UI logic of the iOS app is `totem-bridge`, a native library written in Rust and
statically linked. This is so that it can easily share the Serde & the gRPC networking code so
there's no "implementing networking, serialization, and core logic multiple times" problem (Don't
Repeat Yourself (DRY)).

This is done via 2 more cross-compiling Rust toolchains (`aarch64-apple-ios` (device),
`x86_64-apple-ios` (simulator for my machine)). The cross-linkers can be found in Xcode.

The UI is native SwiftUI and relatively "naive". It uses a generated C header to make C-ABI calls
into the Rust library. It more or less creates a "channel" object and then reads and writes streams
of [messages](https://github.com/winstonli/totem/blob/8f77beb374f4b0ac0e64d491614903e283ae8be1/totem-client/src/ui_msg.rs).

Swift ARC is nice for managing Rust `Box<>`s. It's certainly better than GC but falls short of Rust
lifetimes. The whole thing is nicely composed with all the SwiftUI-specific Reactive Programming
primitives.

The network protocol is gRPC byte arrays + these [messages](https://github.com/winstonli/totem/blob/8f77beb374f4b0ac0e64d491614903e283ae8be1/totem-common/src/msg.rs).

### Networking in a "noisy" environment

[Failure Detector](https://en.wikipedia.org/wiki/Failure_detector) &
[Exponential Backoff](https://en.wikipedia.org/wiki/Exponential_backoff): two things that are simple
to compose with the networking make the app responsive when the network is unstable.

This is important in a festival environment. We don't want the totem to poop its pants during the
Language drop. not literally anyway.

The Failure Detector is just server-to-client Heartbeats with an aggressive timeout. The Wi-Fi is
very good but the P99 latency is still around 1000 ms. As such, the totem sends a heartbeat every
750ms and the client re-connects after 2,000 ms without a heartbeat.

Exponential backoff is self explanatory. Rust co-routines (thank you again Erlang) and static
detection of pretty much all data races (thank you Send and Sync) makes these nice to write and it
pretty much worked the first time after type-checking.

(This is all on top of the regular detection of the TCP / HTTP/2 / gRPC connection
closing. But relying on TCP FIN or keepalive packets & the kernel is never fun.)

### Performance

#### Totem

The difficult thing here is that there is a driver thread at ~75% CPU continuously writing the frame
buffer signal to the displays and that's just [how they work](https://en.wikipedia.org/wiki/Pulse-width_modulation). The only way to mitigate it is to offload it to a custom
chip, which we cannot do.

To avoid flickering during a context switch, the driver thread uses the POSIX scheduler CPU affinity
function to take a core all for itself.

Apart from that, there is no fixed-step "main loop" (it's all async co-routines and Rust manages to
implement Futures/Promises on the stack). As such, dancing Potaro uses ~2.5% CPU across the remaining threads, and ~26.5MB memory.

With Doom, CPU usage is ~60% and memory usage goes up to ~29MB.

#### iOS App

The iOS app, idk, I have to sideload it just to run it. I can't get Big Sur to attach to the device
(iOS too new and don't want to spend a day upgrading & fixing toolchain stuff). In debug mode on the
simulator (with `totem-bridge` built with `--release`) it uses 0% CPU and ~24MB of memory. It's
mostly display & radios using power.

### "Apps"

The totem runs various "apps".

#### Dancer

This is the main app with Potaro dancing. Co-routines, Send and Sync make animation timing here very
easy to de-couple from the rest of the program without sacrificing performance. This code pretty
much worked after it type-checked. The tricky part is to make sure the animation stays in phase
while changing between dances so you don't need to re-sync it with the music.

Various libraries are used for image decoding and text rendering (`> IS ANYONE THERE?`).

#### Doom

It's pretty much a rite of passage to run Doom on novel hardware 🥲

It's quite easy if you're comfortable with C, linking, and native toolchains. Here's how:

1. Remove all display, input and sound code. 

    [doomgeneric](https://github.com/ozkl/doomgeneric) was a great starting point as they've completely decoupled this I/O from the rest of the code.

2. Write frame buffer to a pipe, read "keyboard input" from another pipe.

Then it's just another "app" on the totem, which just boils down to good resource management of the
Doom stuff (the process & pipes) with RAII.

The [iOS App (remote control)](#ios-app) sends input to the [server (totem)](#totem-program) and
writes it to the "keyboard input" pipe, one byte per key, positive for down and negative for up. We
can even use cheats!

Holding a key down works similarly to the
[heartbeat/failure detector implementation](#networking-in-a-noisy-environment)
to mitigate latency: it must continually send messages while it is held down, and the server treats
a timeout as a key-up event if it doesn't actually receive a key-up.

The server reads 320x200 4-byte pixels from the frame buffer pipe, scales it to 128x96, then draws
it.

Save and load game works as it's just `stdio`.

If you have it, I suggest putting `DOOM.WAD` for the full game in the root directory before
following
[Quick Start](#quick-start-simulators-only).
The script will download the shareware version if there isn't anything there, which is missing levels and weapons.

https://user-images.githubusercontent.com/3519080/169437263-6018bf77-3275-483f-b07d-2b35ffb7ad18.mp4

https://user-images.githubusercontent.com/3519080/169437274-9d7ee039-d3e1-496a-8978-08f053e3fe79.mp4

### Hardware

#### Display

The display is 6 64x32 LED panels. They take frame buffer data and power.

Frame buffer data is written using [rpi-rgb-led-matrix](https://github.com/hzeller/rpi-rgb-led-matrix) as mentioned earlier.

Power is just 5V+ and 5V- connections which can be gotten from USB by cutting open the cable.
| Match the red (+) and black (-)       | Plug it in |
| ----------- | ----------- |
![IMG_6346](https://user-images.githubusercontent.com/3519080/169442254-99431022-a3b0-440f-b8f5-7c1a1ba6b70b.jpeg) | ![IMG_6355](https://user-images.githubusercontent.com/3519080/169442261-8d6a293a-4a4f-4e12-8df4-abeb97da8af3.jpeg)

#### Computer

The computer is a RPi Zero W 2. It has this
[adapter board](https://www.electrodragon.com/product/rgb-matrix-panel-drive-board-raspberry-pi/)
([created by the `rpi-rgb-led-matrix` library author](https://github.com/hzeller/rpi-rgb-led-matrix/tree/master/adapter)) attached to it to boost the voltage of the
display signal delivered by the GPIO pins from 3.3V to the 5V needed by the display.

It has Wi-Fi. We commandeer the Wi-Fi hardware with `hostapd` and create a private access point
which the iOS app connects to. I couldn't be bothered with DHCP but it's fine, just statically
allocate the IP address.

It also has Bluetooth (no thanks).

#### Batteries

There are 3 batteries, 2 panels per battery. They were the lightest high-quality 10,000 mAh battery
with a USB-A port that can do 5V/3A and a USB-C port. The RPi is connected to the USB-C port of the
least loaded battery.

The most power hungry pair of panels drains ~32Wh over about 4 hours before its battery dies (2/3 of
the advertised battery capacity).

That's about 8W. So probably 20W across 6 panels.

The RPi uses ~1.25W with Potaro, and 1.5-2.1W with Doom.

Estimated power usage is 20-25W.

#### Wood, etc.

And then finally, a bunch of rubbish DIY with wood and we have the totem!

![IMG_6930](https://user-images.githubusercontent.com/3519080/169248372-50ca8794-7866-46b9-a04b-609180714f7c.jpg)
