# Tesla Roadster Runner

A Tesla Roadster model and driving course made for LunCoSim.

## Run it in LunCoSim

1. [Download LunCoSim](https://lunco.space/download) and install it for your operating system.
2. [Download this model](https://github.com/LunCoSim/roadster) as a ZIP and extract it, or clone it with `git clone https://github.com/LunCoSim/roadster.git`.
3. In LunCoSim, choose **Open Twin** and select the extracted project folder containing `twin.toml`. It opens the **Roadster Cinematic** scene automatically.
4. Choose **Run Autopilot** to watch, or focus the simulator window and drive with **W/S**, **A/D**, **Space**, and **Shift**.

See the [loading guide](docs/loading.md) for the full steps and common fixes.

## About the model

This Twin includes the car, a driving course, and the models that make it drive.

## Results

The current validation record reports that all seven full-course criteria pass in graphical LunCoSim and at both 60 Hz and 10 Hz simulation updates. A completed run takes 29.52 seconds of simulation time. See [wheel-contact and qualification results](references/wheel-contact.md) for the detailed evidence and limits.

## Guides

- [Driving and controls](docs/driving.md)
- [Model details](docs/model.md)
- [Other scenes and project tools](docs/development.md)
- [Sources and assumptions](references/README.md)
- [Wheel contact and qualification](references/wheel-contact.md)
