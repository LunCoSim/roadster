# Load the Roadster model in LunCoSim

You need LunCoSim and the Roadster project folder. You do not need to build the project or use the terminal.

## 1. Install LunCoSim

Go to the [official LunCoSim download page](https://lunco.space/download), download the package for your operating system, and install or launch it.

## 2. Download the Roadster project

Open the [Roadster project page](https://github.com/LunCoSim/roadster). Select **Code → Download ZIP**, then extract the ZIP somewhere easy to find. Keep the extracted folder structure intact.

You can also use Git from a terminal:

```sh
git clone https://github.com/LunCoSim/roadster.git
```

## 3. Open the Twin

1. Start LunCoSim.
2. Choose **Open Twin**.
3. Select the Roadster project folder: `roadster-main` if you extracted the ZIP, or `roadster` if you cloned the repository.
4. Confirm that you selected the folder containing `twin.toml`.

Select the folder, not `scenes/roadster_cinematic.usda`. The Twin manifest sets **Roadster Cinematic** as the default scene, so LunCoSim opens it when the folder loads.

## 4. Watch or drive

Choose **Run Autopilot** to watch the course. To drive, click the 3D scene to focus it, then use **W/S** to accelerate or reverse, **A/D** to steer, **Space** to boost, and **Shift** to brake. **K** controls the lift jets and **F** toggles the fans. See [Driving and controls](driving.md) for the full key map.

## If it does not load

- If LunCoSim reports that this is not a Twin, select the project folder containing `twin.toml`; do not select a scene file or one of the folders inside the project.
- If you downloaded the ZIP, extract it before opening it in LunCoSim.
- Keep the project folders together. The Twin uses its `scenes`, `models`, `components`, and `scenarios` folders when it loads.
