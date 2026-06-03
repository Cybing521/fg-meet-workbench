#!/usr/bin/env python3
"""Draw a schematic of the FG-MEE layered plate/shell model.

The figure is conceptual and is intended for the methods section. It does not
plot simulation output. It shows how the 10 through-thickness layers receive
graded material properties and how the porosity modes are interpreted.
"""

from __future__ import annotations

from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Circle, FancyArrowPatch, Polygon, Rectangle


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "paper" / "figures"
PNG_PATH = OUT_DIR / "fg_gradient_shell_schematic.png"
SVG_PATH = OUT_DIR / "fg_gradient_shell_schematic.svg"


def fg_profiles(z: np.ndarray, vf0: float = 0.6) -> dict[str, np.ndarray]:
    """Return representative through-thickness BaTiO3 volume fraction curves."""
    zeta = z + 0.5
    zbar = np.abs(z) / 0.5
    return {
        "U": np.full_like(z, vf0),
        "V": vf0 * zeta,
        "X": vf0 * zbar,
        "O": np.clip(vf0 * (2.0 - zbar), 0.0, 1.0),
        "P": vf0 * zeta**2,
    }


def porosity_factors(z: np.ndarray, e0: float = 0.3) -> dict[str, np.ndarray]:
    """Representative property retention factors for the three porosity modes."""
    zbar = np.abs(z) / 0.5
    # Keep the log curve finite at the surfaces for a clean conceptual plot.
    log_shape = np.log1p(2.2 * (1.0 - zbar)) / np.log1p(2.2)
    return {
        "Even": np.full_like(z, 1.0 - e0),
        "Uneven": 1.0 - e0 * (1.0 - zbar),
        "LogUneven": 1.0 - e0 * log_shape,
    }


def layer_color(value: float) -> tuple[float, float, float, float]:
    """Map low/high BaTiO3 fraction to CFO/BTO color."""
    return mpl.colormaps["coolwarm"](0.12 + 0.76 * value)


def draw_shell(ax: plt.Axes) -> None:
    ax.set_xlim(-0.4, 6.2)
    ax.set_ylim(-0.6, 3.2)
    ax.axis("off")

    n_layers = 10
    x0, y0 = 0.45, 0.85
    width, height = 4.15, 1.12
    dx, dy = 0.82, 0.48
    layer_h = height / n_layers

    # X-type sketch: surfaces are BTO-rich, mid-plane is CFO-rich.
    layer_mid = np.linspace(-0.5 + 0.5 / n_layers, 0.5 - 0.5 / n_layers, n_layers)
    bto_fraction = np.abs(layer_mid) / 0.5

    # Top surface.
    top_color = layer_color(float(bto_fraction[-1]))
    ax.add_patch(
        Polygon(
            [(x0, y0 + height), (x0 + dx, y0 + height + dy),
             (x0 + width + dx, y0 + height + dy), (x0 + width, y0 + height)],
            closed=True,
            facecolor=top_color,
            edgecolor="#444444",
            linewidth=0.8,
        )
    )

    # Side face.
    ax.add_patch(
        Polygon(
            [(x0 + width, y0), (x0 + width + dx, y0 + dy),
             (x0 + width + dx, y0 + height + dy), (x0 + width, y0 + height)],
            closed=True,
            facecolor="#e6e6e6",
            edgecolor="#444444",
            linewidth=0.8,
            alpha=0.95,
        )
    )

    # Front layer strips.
    for i, vf in enumerate(bto_fraction):
        y = y0 + i * layer_h
        rect = Rectangle(
            (x0, y),
            width,
            layer_h,
            facecolor=layer_color(float(vf)),
            edgecolor="white",
            linewidth=0.8,
        )
        ax.add_patch(rect)

    ax.add_patch(Rectangle((x0, y0), width, height, fill=False, edgecolor="#333333", linewidth=1.0))

    # Pores, concentrated near the mid-plane.
    pore_specs = [
        (1.00, 0.50, 0.045), (1.45, 0.55, 0.035), (1.92, 0.49, 0.040),
        (2.38, 0.61, 0.030), (2.86, 0.48, 0.050), (3.35, 0.57, 0.036),
        (3.78, 0.50, 0.032), (2.05, 0.32, 0.026), (3.02, 0.77, 0.024),
    ]
    for px, py, radius in pore_specs:
        ax.add_patch(
            Circle(
                (x0 + px, y0 + py),
                radius,
                facecolor="white",
                edgecolor="#555555",
                linewidth=0.7,
                alpha=0.95,
            )
        )

    # Layer index markers.
    for i in range(n_layers + 1):
        y = y0 + i * layer_h
        ax.plot([x0 - 0.06, x0], [y, y], color="#333333", lw=0.6)
    ax.text(x0 - 0.18, y0 + height / 2, "10 layers", rotation=90, va="center", ha="center", fontsize=8)

    # Callouts.
    arrow_kw = dict(arrowstyle="-|>", mutation_scale=10, linewidth=0.9, color="#333333")
    ax.add_patch(FancyArrowPatch((x0 + width + 0.75, y0), (x0 + width + 0.75, y0 + height + 0.35), **arrow_kw))
    ax.text(x0 + width + 0.92, y0 + height / 2 + 0.15, "z", va="center", fontsize=9)
    ax.text(x0 + 0.15, y0 + height + dy + 0.18, "BTO-rich outer layer", fontsize=8.3, color="#9a3412")
    ax.text(x0 + 0.20, y0 + height / 2 - 0.05, "CFO-rich mid-plane\nwith pores", fontsize=8.3, color="#1e3a8a")
    ax.text(x0 + 0.15, y0 - 0.30, "Layer-wise material assignment for COMSOL/MATLAB", fontsize=8.3)
    ax.set_title("Layered FG-MEE plate/shell model", loc="left", fontsize=10, fontweight="bold")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    mpl.rcParams.update(
        {
            "figure.dpi": 160,
            "savefig.dpi": 300,
            "font.family": "DejaVu Sans",
            "font.size": 8.5,
            "axes.linewidth": 0.8,
            "svg.fonttype": "none",
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
        }
    )

    fig = plt.figure(figsize=(7.2, 3.8), constrained_layout=True)
    gs = fig.add_gridspec(2, 2, width_ratios=[1.25, 1.0], height_ratios=[1.0, 1.0])
    ax_shell = fig.add_subplot(gs[:, 0])
    ax_fg = fig.add_subplot(gs[0, 1])
    ax_pore = fig.add_subplot(gs[1, 1])

    draw_shell(ax_shell)

    z = np.linspace(-0.5, 0.5, 300)
    colors = {"U": "#4d4d4d", "V": "#0072B2", "X": "#D55E00", "O": "#009E73", "P": "#CC79A7"}
    for name, values in fg_profiles(z).items():
        ax_fg.plot(values, z, lw=1.6, color=colors[name], label=name)
    ax_fg.set_title("FG profiles", fontsize=9.5, loc="left", fontweight="bold")
    ax_fg.set_xlabel(r"$V_f(z)$ of BaTiO$_3$")
    ax_fg.set_ylabel(r"$z/h$")
    ax_fg.set_xlim(-0.02, 1.05)
    ax_fg.set_ylim(-0.52, 0.52)
    ax_fg.grid(True, alpha=0.25, lw=0.5)
    ax_fg.legend(frameon=False, ncol=3, loc="lower right", fontsize=7.5, handlelength=1.2)

    p_colors = {"Even": "#4d4d4d", "Uneven": "#0072B2", "LogUneven": "#D55E00"}
    for name, values in porosity_factors(z).items():
        ax_pore.plot(values, z, lw=1.6, color=p_colors[name], label=name)
    ax_pore.set_title("Porosity property retention", fontsize=9.5, loc="left", fontweight="bold")
    ax_pore.set_xlabel(r"$P_{\mathrm{eff}} / P_{\mathrm{dense}}$")
    ax_pore.set_ylabel(r"$z/h$")
    ax_pore.set_xlim(0.64, 1.03)
    ax_pore.set_ylim(-0.52, 0.52)
    ax_pore.grid(True, alpha=0.25, lw=0.5)
    ax_pore.legend(frameon=False, loc="lower right", fontsize=7.5)

    fig.suptitle("Functionally graded material distribution and porous plate/shell interpretation", fontsize=11)
    fig.savefig(PNG_PATH, bbox_inches="tight")
    fig.savefig(SVG_PATH, bbox_inches="tight")
    plt.close(fig)
    print(PNG_PATH)
    print(SVG_PATH)


if __name__ == "__main__":
    main()
