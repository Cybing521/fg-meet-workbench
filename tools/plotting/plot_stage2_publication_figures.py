"""Generate publication figures for the corrected Stage-2 validation report."""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

from scimplstyle_mssp import (
    apply_sci_style,
    apply_tight_layout,
    figure_size,
    panel_label,
    safe_legend,
    save_figure,
)


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "outputs" / "paper-20260715-fgmee"
FIG_DIR = BASE / "figures"
CURV = BASE / "experiments" / "curvature_fg"
INV = BASE / "experiments" / "inverse_sensing"

BLUE = "#377EB8"
RED = "#E41A1C"
BLACK = "#222222"
GRAY = "#777777"


def configure_axis(ax: plt.Axes) -> None:
    ax.grid(axis="y", alpha=0.45)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)


def curvature_figure() -> list[Path]:
    pilot = pd.read_csv(CURV / "curvature_fg_pilot_10x10.csv")
    interaction = pd.read_csv(CURV / "curvature_fg_interaction_10x10.csv")
    final = pd.read_csv(CURV / "curvature_fg_displacement_interaction_final.csv")

    fig, axes = plt.subplots(1, 3, figsize=figure_size("double", 0.34))
    styles = {"U": (BLUE, "o"), "X": (RED, "s")}

    for mode, (color, marker) in styles.items():
        data = pilot[(pilot["mode"] == mode) & (pilot["load_case"] == "elastic")].sort_values("curvature_1pm")
        axes[0].plot(
            data["curvature_1pm"], data["abs_w_ratio_to_flat"],
            color=color, marker=marker, markerfacecolor="white", label=f"{mode} gradient",
        )
    axes[0].set_xlabel(r"curvature (m$^{-1}$)")
    axes[0].set_ylabel("normalized center dis.")
    axes[0].set_title("Pressure-driven response")
    safe_legend(axes[0], loc="lower left")
    configure_axis(axes[0])
    panel_label(axes[0], "(a)", y=1.14)

    for mode, (color, marker) in styles.items():
        data = pilot[(pilot["mode"] == mode) & (pilot["load_case"] == "electro")].sort_values("curvature_1pm")
        axes[1].plot(
            data["curvature_1pm"], data["abs_w_ratio_to_flat"],
            color=color, marker=marker, markerfacecolor="white", label=f"{mode} screening",
        )
        verified = final[final["load_case"] == "electro"].iloc[0]
        y = verified[f"{mode}_curvature_ratio"]
        axes[1].scatter([2.5], [y], s=34, color=color, marker=marker, zorder=5, label=f"{mode} verified")
    axes[1].set_xlabel(r"curvature (m$^{-1}$)")
    axes[1].set_ylabel("normalized center dis.")
    axes[1].set_title("Electric/magnetic actuation")
    safe_legend(axes[1], loc="lower right", ncol=1, fontsize=7.5)
    configure_axis(axes[1])
    panel_label(axes[1], "(b)", y=1.14)

    screened = interaction[
        (interaction["load_case"] == "electro")
        & (interaction["metric"] == "abs_w_ratio_to_flat")
    ].sort_values("curvature_1pm")
    axes[2].plot(
        screened["curvature_1pm"],
        screened["gradient_curvature_interaction_pct_point"],
        color=GRAY, marker="o", markerfacecolor="white", label="10x10 screening",
    )
    verified = final[final["load_case"] == "electro"].iloc[0]
    axes[2].scatter(
        [2.5], [verified["gradient_curvature_interaction_pct_point"]],
        color=BLACK, marker="D", s=38, zorder=6, label="20x20/30x30 verified",
    )
    axes[2].axhline(0.0, color="0.65", linewidth=0.8)
    axes[2].annotate(
        f"{verified['gradient_curvature_interaction_pct_point']:.3f} pp\n"
        f"mesh change {verified['max_20_to_30_curved_w_change_pct']:.3f}%",
        xy=(2.5, verified["gradient_curvature_interaction_pct_point"]),
        xytext=(2.8, 1.12),
        arrowprops={"arrowstyle": "->", "lw": 0.7, "color": "0.35"},
        fontsize=7.5,
    )
    axes[2].set_xlabel(r"curvature (m$^{-1}$)")
    axes[2].set_ylabel("interaction (percentage points)")
    axes[2].set_title("Gradient-curvature interaction")
    safe_legend(axes[2], loc="lower right", fontsize=7.5)
    configure_axis(axes[2])
    panel_label(axes[2], "(c)", y=1.14)

    apply_tight_layout(fig, pad=0.45, w_pad=1.6, h_pad=0.8)
    written = save_figure(
        fig,
        "Fig_01_curvature_gradient_interaction",
        out_dir=FIG_DIR,
        formats=("png", "pdf"),
        dpi=600,
        pad_inches=0.05,
    )
    plt.close(fig)
    return written


def inverse_figure() -> list[Path]:
    data = pd.read_csv(INV / "inverse_sensor_corrected_comparison.csv")
    data = data[data["mesh_inplane"] == 20].sort_values("target_w_mm")

    fig, axes = plt.subplots(1, 2, figsize=figure_size("double", 0.34))
    panels = [
        (
            axes[0], "Electric potential", "potential span (V)",
            "matlab_legacy_e_V", "matlab_corrected_e_V", "comsol_corrected_e_V",
        ),
        (
            axes[1], "Magnetic potential", "potential span (A)",
            "matlab_legacy_m_A", "matlab_corrected_m_A", "comsol_corrected_m_A",
        ),
    ]
    for i, (ax, title, ylabel, legacy, corrected, comsol) in enumerate(panels):
        x = data["target_w_mm"]
        ax.plot(x, data[legacy], color=GRAY, linestyle="--", marker="x", label="legacy MATLAB")
        ax.plot(x, data[corrected], color=BLUE, marker="o", markerfacecolor="white", label="corrected MATLAB")
        ax.plot(x, data[comsol], color=RED, marker="s", markerfacecolor="white", label="COMSOL 3D postprocess")
        ax.set_xlabel("target center dis. (mm)")
        ax.set_ylabel(ylabel)
        ax.set_title(title)
        safe_legend(ax, loc="upper left", fontsize=8)
        configure_axis(ax)
        panel_label(ax, f"({chr(ord('a') + i)})", y=1.14)
    apply_tight_layout(fig, pad=0.45, w_pad=2.0, h_pad=0.8)
    written = save_figure(
        fig,
        "Fig_02_inverse_sensor_correction",
        out_dir=FIG_DIR,
        formats=("png", "pdf"),
        dpi=600,
        pad_inches=0.05,
    )
    plt.close(fig)
    return written


def main() -> None:
    apply_sci_style(base_size=9)
    paths = curvature_figure() + inverse_figure()
    for path in paths:
        print(path)


if __name__ == "__main__":
    main()
