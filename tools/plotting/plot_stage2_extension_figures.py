"""Publication figures for the isomorphic, all-radius, and curved-COMSOL extension."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
VENDORED = ROOT / "tmp" / "plot_pydeps"
if VENDORED.is_dir():
    sys.path.insert(0, str(VENDORED))

import matplotlib as mpl

mpl.use("Agg")

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


BASE = ROOT / "outputs" / "paper-20260715-fgmee"
FIG_DIR = BASE / "figures"
ISO = BASE / "experiments" / "isomorphic_solid"
CURV = BASE / "experiments" / "curvature_fg"
BLUE = "#377EB8"
RED = "#E41A1C"
GREEN = "#4DAF4A"
BLACK = "#222222"
GRAY = "#777777"


def configure_axis(ax: plt.Axes, grid_axis: str = "y") -> None:
    ax.grid(axis=grid_axis, alpha=0.42)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)


def isomorphic_figure() -> list[Path]:
    data = pd.read_csv(ISO / "isomorphic_solid_cross_solver_comparison.csv")
    fig, axes = plt.subplots(1, 3, figsize=figure_size("double", 0.34))
    cases = [
        ("electric_equivalent_stress", axes[0], "Electric-equivalent stress", "center dis. (mm)"),
        ("magnetic_external_stress", axes[1], "Magnetic-equivalent stress", "center dis. (mm)"),
    ]
    for i, (case, ax, title, ylabel) in enumerate(cases):
        d = data[data["load_case"] == case].sort_values("inplane_divisions")
        ax.plot(d["inplane_divisions"], d["matlab_w_center_mm"], color=BLUE,
                marker="o", markerfacecolor="white", label="MATLAB H20")
        ax.plot(d["inplane_divisions"], d["comsol_w_center_mm"], color=RED,
                linestyle="--", marker="s", markerfacecolor="white", label="COMSOL solid")
        ax.set_xlabel("in-plane divisions")
        ax.set_ylabel(ylabel)
        ax.set_title(title)
        safe_legend(ax, loc="best", fontsize=7.5)
        configure_axis(ax)
        panel_label(ax, f"({chr(ord('a') + i)})", y=1.14)

    for case, color, marker, label, x_offset in (
        ("electric_equivalent_stress", BLUE, "o", "electric", -0.08),
        ("magnetic_external_stress", RED, "s", "magnetic", 0.08),
    ):
        d = data[data["load_case"] == case].sort_values("inplane_divisions")
        axes[2].semilogy(
            d["inplane_divisions"] + x_offset, d["center_relative_error_pct"],
            color=color, marker=marker, markerfacecolor="white", label=label,
        )
    axes[2].axhline(0.1, color=GRAY, linestyle=":", linewidth=0.9, label="0.1% gate")
    axes[2].set_xlabel("in-plane divisions")
    axes[2].set_ylabel("cross-solver error (%)")
    axes[2].set_title("Isomorphic closure")
    safe_legend(axes[2], loc="upper left", fontsize=7.5)
    configure_axis(axes[2], grid_axis="both")
    panel_label(axes[2], "(c)", y=1.14)
    apply_tight_layout(fig, pad=0.45, w_pad=1.7, h_pad=0.8)
    written = save_figure(
        fig, "Fig_03_isomorphic_solid_closure", out_dir=FIG_DIR,
        formats=("png", "pdf"), dpi=600, pad_inches=0.05,
    )
    plt.close(fig)
    return written


def full_curvature_figure() -> list[Path]:
    final = pd.read_csv(CURV / "curvature_fg_final_30x30_results.csv")
    interaction = pd.read_csv(CURV / "curvature_fg_all_radius_interaction_30x30.csv")
    fig, axes = plt.subplots(1, 3, figsize=figure_size("double", 0.34))
    styles = {"U": (BLUE, "o"), "X": (RED, "s")}
    for panel, load_case, title in (
        (0, "elastic", "Pressure-driven response"),
        (1, "electro", "Electric actuation"),
    ):
        ax = axes[panel]
        for mode, (color, marker) in styles.items():
            d = final[(final["load_case"] == load_case) & (final["mode"] == mode)].sort_values("curvature_1pm")
            y = d["curved_to_flat_abs_ratio"]
            yerr = y * d["w_change_20_to_30_pct"] / 100.0
            ax.errorbar(
                d["curvature_1pm"], y, yerr=yerr,
                color=color, marker=marker, markerfacecolor="white",
                capsize=2.0, linewidth=1.0, label=f"{mode} gradient",
            )
        ax.set_xlabel(r"curvature (m$^{-1}$)")
        ax.set_ylabel("normalized center dis.")
        ax.set_title(title)
        safe_legend(ax, loc="best", fontsize=7.5)
        configure_axis(ax)
        panel_label(ax, f"({chr(ord('a') + panel)})", y=1.14)

    for load_case, color, marker, linestyle, label in (
        ("elastic", BLACK, "^", "-.", "pressure"),
        ("electro", BLUE, "o", "-", "electric"),
        ("magneto", RED, "s", "--", "magnetic"),
    ):
        d = interaction[interaction["load_case"] == load_case].sort_values("curvature_1pm")
        axes[2].plot(
            d["curvature_1pm"], d["gradient_curvature_interaction_pct_point"],
            color=color, marker=marker, linestyle=linestyle,
            markerfacecolor="white", label=label,
        )
        passed = d[d["resolved_above_3x_mesh_bound"] == "pass"]
        axes[2].scatter(
            passed["curvature_1pm"], passed["gradient_curvature_interaction_pct_point"],
            color=color, marker=marker, s=28, zorder=5,
        )
    axes[2].axhline(0.0, color="0.65", linewidth=0.8)
    axes[2].set_xlabel(r"curvature (m$^{-1}$)")
    axes[2].set_ylabel("interaction (percentage points)")
    axes[2].set_title("Gradient-curvature interaction")
    safe_legend(axes[2], loc="best", fontsize=7.5)
    configure_axis(axes[2])
    panel_label(axes[2], "(c)", y=1.14)
    apply_tight_layout(fig, pad=0.45, w_pad=1.6, h_pad=0.8)
    written = save_figure(
        fig, "Fig_04_all_radius_curvature_validation", out_dir=FIG_DIR,
        formats=("png", "pdf"), dpi=600, pad_inches=0.05,
    )
    plt.close(fig)
    return written


def curved_comsol_figure() -> list[Path]:
    conv = pd.read_csv(CURV / "curved_comsol_mesh_convergence.csv").sort_values("axial_divisions")
    comp = pd.read_csv(CURV / "curved_comsol_vs_matlab_model_form_comparison.csv").iloc[0]
    profile = pd.read_csv(
        CURV / "comsol" / "comsol_curved_U_R0p4_20x20x10_final_midarc.csv"
    )
    fig, axes = plt.subplots(1, 2, figsize=figure_size("double", 0.34))
    axes[0].plot(
        conv["axial_divisions"], conv["w_center_radial_mm"],
        color=RED, marker="s", markerfacecolor="white", label="COMSOL 3D solid",
    )
    axes[0].axhline(
        comp["matlab_w_center_mm"], color=BLUE, linestyle="--",
        linewidth=1.0, label="MATLAB LRT5 (20x20)",
    )
    axes[0].set_xlabel("axial/circumferential divisions")
    axes[0].set_ylabel("center radial dis. (mm)")
    axes[0].set_title(r"Curved model, $R=0.4$ m")
    safe_legend(axes[0], loc="best", fontsize=8)
    configure_axis(axes[0])
    panel_label(axes[0], "(a)", y=1.14)

    profile = profile.dropna(subset=["radial_displacement_mm"])
    axes[1].plot(
        profile["theta_over_span"], profile["radial_displacement_mm"],
        color=RED, marker="s", markerfacecolor="white",
    )
    axes[1].set_xlabel(r"normalized arc coordinate, $\theta/\theta_0$")
    axes[1].set_ylabel("radial dis. (mm)")
    axes[1].set_title("COMSOL axial midline")
    configure_axis(axes[1])
    panel_label(axes[1], "(b)", y=1.14)
    apply_tight_layout(fig, pad=0.45, w_pad=2.0, h_pad=0.8)
    written = save_figure(
        fig, "Fig_05_curved_comsol_validation", out_dir=FIG_DIR,
        formats=("png", "pdf"), dpi=600, pad_inches=0.05,
    )
    plt.close(fig)
    return written


def main() -> None:
    apply_sci_style(base_size=9)
    paths = isomorphic_figure() + full_curvature_figure() + curved_comsol_figure()
    for path in paths:
        print(path)


if __name__ == "__main__":
    main()
