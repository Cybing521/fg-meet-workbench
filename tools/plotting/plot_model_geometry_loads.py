"""Draw deterministic FG-MEE geometry, boundary, and load schematics.

The figures are method diagrams, not simulation contours.  Geometry and load
labels are taken from the audited curvature and direct-field model sources:

* axial length = 0.300 m, arc length = 0.300 m, thickness = 0.006 m;
* radii = 1.0, 0.4, 0.3, 0.2 m;
* CFFF boundary at the circumferential start, s = R*theta = 0;
* pressure = 15 kPa; outer active-layer potential spans are 300 V and 200 A.
"""

from __future__ import annotations

import math
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
VENDORED = ROOT / "tmp" / "plot_pydeps"
if VENDORED.is_dir():
    sys.path.insert(0, str(VENDORED))

import matplotlib as mpl

mpl.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
from matplotlib import patheffects
from matplotlib.lines import Line2D
from matplotlib.patches import FancyArrowPatch, Rectangle
from mpl_toolkits.mplot3d import proj3d
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

from scimplstyle_mssp import apply_sci_style, save_figure


FIG_DIR = ROOT / "outputs" / "paper-20260715-fgmee" / "figures"

AXIAL_LENGTH_M = 0.300
ARC_LENGTH_M = 0.300
THICKNESS_M = 0.006
N_LAYERS = 10
PRESSURE_PA = 15_000.0
ELECTRIC_LAYER_SPAN_V = 300.0
MAGNETIC_LAYER_SPAN_A = 200.0
RADII_M = (1.0, 0.4, 0.3, 0.2)

BLUE = "#377EB8"
RED = "#E41A1C"
GREEN = "#4DAF4A"
BLACK = "#222222"
GRAY = "#777777"
LIGHT_BLUE = "#D9EAF4"
LIGHT_GRAY = "#EDF0F2"


def shell_xyz(radius: float, radial_offset: float, x: np.ndarray, theta: np.ndarray):
    """Return the Cartesian embedding used by the COMSOL revolve geometry."""
    rr = radius + radial_offset
    xx, tt = np.meshgrid(x, theta, indexing="ij")
    yy = -rr * np.sin(tt)
    zz = rr * np.cos(tt) - radius
    return xx, yy, zz


def draw_shell_panel(ax, radius: float, panel: str) -> None:
    theta_span = ARC_LENGTH_M / radius
    theta = np.linspace(0.0, theta_span, 31)
    axial = np.linspace(0.0, AXIAL_LENGTH_M, 13)
    outer = shell_xyz(radius, THICKNESS_M / 2.0, axial, theta)
    inner = shell_xyz(radius, -THICKNESS_M / 2.0, axial, theta)

    ax.plot_surface(
        *outer,
        color=LIGHT_BLUE,
        edgecolor="#9FB9C8",
        linewidth=0.25,
        alpha=0.92,
        antialiased=True,
        rstride=2,
        cstride=3,
    )
    ax.plot_surface(
        *inner,
        color=LIGHT_GRAY,
        edgecolor="#B9BEC2",
        linewidth=0.20,
        alpha=0.62,
        antialiased=True,
        rstride=3,
        cstride=4,
    )

    # The fixed through-thickness face at s = R*theta = 0.
    fixed_face = [
        (0.0, 0.0, -THICKNESS_M / 2.0),
        (AXIAL_LENGTH_M, 0.0, -THICKNESS_M / 2.0),
        (AXIAL_LENGTH_M, 0.0, THICKNESS_M / 2.0),
        (0.0, 0.0, THICKNESS_M / 2.0),
    ]
    ax.add_collection3d(
        Poly3DCollection(
            [fixed_face], facecolor=RED, edgecolor="#8B1A1A", linewidth=1.0, alpha=0.92
        )
    )
    ax.plot(
        [0.0, AXIAL_LENGTH_M], [0.0, 0.0],
        [THICKNESS_M / 2.0, THICKNESS_M / 2.0],
        color=RED, linewidth=3.0, solid_capstyle="round",
    )

    # Remaining three outer mid-surface edges are free.
    for x_edge in (0.0, AXIAL_LENGTH_M):
        _, yy, zz = shell_xyz(radius, THICKNESS_M / 2.0, np.array([x_edge]), theta)
        ax.plot(np.full(theta.shape, x_edge), yy[0], zz[0], color=BLUE, linewidth=1.4)
    _, yy_free, zz_free = shell_xyz(
        radius, THICKNESS_M / 2.0, axial, np.array([theta_span])
    )
    ax.plot(axial, yy_free[:, 0], zz_free[:, 0], color=BLUE, linewidth=1.8)

    # Inward normal pressure arrows. Arrow tips remain above the outside
    # surface so Matplotlib's 3D depth sorting cannot hide them at paper size.
    pressure_segments = []
    arrow_sites = ((0.075, 0.24), (0.150, 0.50), (0.225, 0.76))
    for x0, frac in arrow_sites:
        tt = frac * theta_span
        normal = np.array([0.0, -math.sin(tt), math.cos(tt)])
        surface = np.array([
            x0,
            -(radius + THICKNESS_M / 2.0) * math.sin(tt),
            (radius + THICKNESS_M / 2.0) * math.cos(tt) - radius,
        ])
        start = surface + 0.080 * normal
        delta = -0.058 * normal
        pressure_segments.append((start, start + delta))

    # Display the geometric locations just above the outer surface. The radial
    # offset is visual only; the reported curved-shell probe is on the
    # midsurface at the geometric center.
    probe_locations = []
    for frac, glyph, color, size in (
        (0.50, r"$\bullet$", BLACK, 10.5),
        (1.00, r"$\diamond$", GREEN, 12.5),
    ):
        tt = frac * theta_span
        display_radius = radius + THICKNESS_M / 2.0 + 0.010
        probe_locations.append((np.array([
            AXIAL_LENGTH_M / 2.0,
            -display_radius * math.sin(tt),
            display_radius * math.cos(tt) - radius,
        ]), glyph, color, size))

    ax.set_title(
        rf"({panel})  $R={radius:.1f}$ m,  $\theta_0={math.degrees(theta_span):.2f}^\circ$",
        pad=3.0, fontsize=9.2, fontweight="bold",
    )
    ax.text2D(
        0.02, 0.88,
        r"$L_X=300$ mm" + "\n" + r"$s=300$ mm, $h=6$ mm (10 layers)",
        transform=ax.transAxes, fontsize=7.2, va="top",
        bbox={"boxstyle": "round,pad=0.22", "fc": "white", "ec": "0.82", "alpha": 0.88},
    )
    ax.text2D(0.02, 0.12, r"fixed: $s=R\theta=0$", transform=ax.transAxes,
              fontsize=7.2, color="#8B1A1A")
    ax.text2D(0.67, 0.12, "free edge", transform=ax.transAxes,
              fontsize=7.2, color=BLUE)
    ax.text2D(0.70, 0.84, r"$p=15$ kPa", transform=ax.transAxes,
              fontsize=7.4, color=BLACK, fontweight="bold")

    # Common physical limits preserve the visible change in curvature.
    ax.set_xlim(0.0, AXIAL_LENGTH_M)
    ax.set_ylim(-0.315, 0.035)
    ax.set_zlim(-0.215, 0.045)
    ax.set_box_aspect((1.0, 1.0, 0.62))
    ax.view_init(elev=22, azim=-58)

    # Project arrows and markers back onto the 2D canvas after the 3D view is
    # fixed. These overlays preserve the true projected locations while
    # preventing translucent surfaces from occluding method annotations.
    outline = [patheffects.Stroke(linewidth=2.4, foreground="white"),
               patheffects.Normal()]
    for start, end in pressure_segments:
        sx, sy, _ = proj3d.proj_transform(*start, ax.get_proj())
        ex, ey, _ = proj3d.proj_transform(*end, ax.get_proj())
        annotation = ax.annotate(
            "", xy=(ex, ey), xytext=(sx, sy),
            xycoords="data", textcoords="data",
            arrowprops={"arrowstyle": "-|>", "color": BLACK, "lw": 1.8},
            zorder=100,
        )
        annotation.arrow_patch.set_path_effects(outline)
    for location, glyph, color, size in probe_locations:
        px, py, _ = proj3d.proj_transform(*location, ax.get_proj())
        marker = ax.annotate(
            glyph, xy=(px, py), xycoords="data", ha="center", va="center",
            fontsize=size, color=color, zorder=101,
        )
        marker.set_path_effects(outline)
    ax.set_axis_off()


def geometry_figure() -> list[Path]:
    fig = plt.figure(figsize=(7.0, 5.25))
    axes = [fig.add_subplot(2, 2, i + 1, projection="3d") for i in range(4)]
    for panel, radius, ax in zip("abcd", RADII_M, axes, strict=True):
        draw_shell_panel(ax, radius, panel)

    handles = [
        Line2D([0], [0], color=RED, linewidth=3.0, label=r"fixed edge, $s=0$"),
        Line2D([0], [0], color=BLUE, linewidth=1.7, label="free edges"),
        Line2D([0], [0], color=BLACK, marker=r"$\downarrow$", linestyle="None",
               markersize=8, label="inward pressure, 15 kPa"),
        Line2D([0], [0], color=BLACK, marker="o", linestyle="None",
               markeredgecolor="white", label="geometric center probe"),
        Line2D([0], [0], color=GREEN, marker="D", linestyle="None",
               markerfacecolor="white", markeredgecolor=GREEN, markeredgewidth=1.5,
               label="free-edge midpoint reference"),
    ]
    fig.legend(
        handles=handles, loc="lower center", ncol=3, frameon=False,
        bbox_to_anchor=(0.5, 0.005), fontsize=7.7,
    )
    fig.subplots_adjust(left=0.01, right=0.99, top=0.98, bottom=0.11, wspace=0.01, hspace=0.15)
    setattr(fig, "_scimplstyle_layout_applied", True)
    paths = save_figure(
        fig, "Fig_00_curved_shell_geometry_loads", out_dir=FIG_DIR,
        formats=("png", "pdf"), dpi=600, pad_inches=0.04,
    )
    plt.close(fig)
    return paths


def draw_pressure_panel(ax) -> None:
    radius = 0.4
    theta_span = ARC_LENGTH_M / radius
    tt = np.linspace(0.0, theta_span, 160)
    # True circular cross-section coordinates. Using arc length as a Cartesian
    # abscissa would make radial arrows non-normal to the displayed curve.
    x = radius * np.sin(tt)
    z = radius * np.cos(tt) - radius
    ax.plot(x, z, color=BLACK, linewidth=2.0)
    ax.plot([0.0, 0.0], [-0.030, 0.030], color=RED, linewidth=4.0)
    for zz in np.linspace(-0.026, 0.026, 8):
        ax.plot([-0.018, 0.0], [zz - 0.010, zz], color=RED, linewidth=0.7)
    for frac in (0.20, 0.40, 0.60, 0.80):
        idx = int(frac * (len(tt) - 1))
        outward = np.array([math.sin(tt[idx]), math.cos(tt[idx])])
        start = np.array([x[idx], z[idx]]) + 0.052 * outward
        end = np.array([x[idx], z[idx]]) + 0.006 * outward
        ax.annotate("", xy=end, xytext=start,
                    arrowprops={"arrowstyle": "-|>", "color": BLACK, "lw": 1.3})
    ax.text(0.155, 0.035, r"$p=15$ kPa", ha="center", fontsize=8.5)
    ax.text(0.006, -0.055, r"fixed $s=0$", color="#8B1A1A", fontsize=7.5)
    ax.text(0.292, z[-1] - 0.020, "free", color=BLUE, ha="right", fontsize=7.5)
    ax.set_xlim(-0.025, 0.325)
    ax.set_ylim(-0.155, 0.085)
    ax.set_aspect("equal", adjustable="box")
    ax.axis("off")
    ax.set_title("(b) Normal pressure and CFFF edge", fontsize=9.2, fontweight="bold", pad=3)


def draw_active_layers_panel(ax) -> None:
    x0, width = 0.20, 0.44
    layer_h = 0.075
    y0 = 0.08
    for i in range(N_LAYERS):
        is_active = i in (0, N_LAYERS - 1)
        face = "#DDEAF6" if is_active else ("#F2F3F4" if i % 2 == 0 else "#E6E8EA")
        ax.add_patch(Rectangle((x0, y0 + i * layer_h), width, layer_h,
                               facecolor=face, edgecolor="white", linewidth=0.8))
    ax.add_patch(Rectangle((x0, y0), width, N_LAYERS * layer_h,
                           fill=False, edgecolor=BLACK, linewidth=0.9))

    electric_x = x0 + width + 0.11
    magnetic_x = electric_x + 0.075
    bottom_mid = y0 + 0.5 * layer_h
    top_mid = y0 + (N_LAYERS - 0.5) * layer_h
    for y, dy in ((bottom_mid - 0.030, 0.060), (top_mid + 0.030, -0.060)):
        ax.annotate("", xy=(electric_x, y + dy), xytext=(electric_x, y),
                    arrowprops={"arrowstyle": "-|>", "color": BLUE, "lw": 1.4})
        ax.annotate("", xy=(magnetic_x, y + dy), xytext=(magnetic_x, y),
                    arrowprops={"arrowstyle": "->", "color": RED, "lw": 1.4,
                                "linestyle": "--"})
    ax.text(electric_x, 0.90, r"$E_3$", ha="center", va="center",
            fontsize=7.2, color=BLUE)
    ax.text(magnetic_x, 0.90, r"$H_3$", ha="center", va="center",
            fontsize=7.2, color=RED)
    ax.text(x0 - 0.115, y0 + N_LAYERS * layer_h / 2,
            "10 layers", ha="center", va="center", rotation=90, fontsize=8.0)
    ax.text(x0 - 0.03, bottom_mid, "active", ha="right", va="center", fontsize=7.2, color=BLUE)
    ax.text(x0 - 0.03, top_mid, "active", ha="right", va="center", fontsize=7.2, color=BLUE)
    ax.text(0.54, 0.015, r"$\phi$: 300 V (outer), 0 V (inner)", color=BLUE,
            ha="center", va="top", fontsize=6.5)
    ax.text(0.54, -0.060, r"$\psi$: 200 A (outer), 0 A (inner)", color=RED,
            ha="center", va="top", fontsize=6.5)
    ax.text(0.13, -0.020, r"$h_\ell=0.6$ mm",
            ha="center", va="top", fontsize=7.5)
    ax.set_xlim(0.0, 1.0)
    ax.set_ylim(-0.13, 1.0)
    ax.axis("off")
    ax.set_title("(c) Electric and magnetic outer layers", fontsize=9.2,
                 fontweight="bold", pad=3)


def material_load_figure() -> list[Path]:
    fig, axes = plt.subplots(1, 3, figsize=(7.0, 2.55))

    z_mid = np.linspace(-0.45, 0.45, N_LAYERS)
    u = np.full_like(z_mid, 0.6)
    x_profile = 0.6 * np.abs(z_mid) / 0.5
    for y in np.linspace(-0.5, 0.5, N_LAYERS + 1):
        axes[0].axhline(y, color="0.90", linewidth=0.45, zorder=0)
    axes[0].plot(u, z_mid, color=BLUE, marker="o", markerfacecolor="white", label="U")
    axes[0].plot(x_profile, z_mid, color=RED, marker="s", markerfacecolor="white", label="X")
    axes[0].set_xlabel(r"BaTiO$_3$ volume fraction, $V_{\rm BTO}$")
    axes[0].set_ylabel(r"normalized thickness, $z/h$")
    axes[0].set_xlim(-0.02, 0.66)
    axes[0].set_ylim(-0.52, 0.52)
    axes[0].grid(axis="x", alpha=0.30)
    axes[0].legend(frameon=False, loc="center left", fontsize=8)
    axes[0].spines[["top", "right"]].set_visible(False)
    axes[0].set_title("(a) Ten-layer U/X material profiles", fontsize=9.2,
                      fontweight="bold", pad=3)

    draw_pressure_panel(axes[1])
    draw_active_layers_panel(axes[2])
    fig.subplots_adjust(left=0.07, right=0.995, top=0.88, bottom=0.25, wspace=0.30)
    setattr(fig, "_scimplstyle_layout_applied", True)
    paths = save_figure(
        fig, "Fig_00_material_boundary_loads", out_dir=FIG_DIR,
        formats=("png", "pdf"), dpi=600, pad_inches=0.04,
    )
    plt.close(fig)
    return paths


def validate_inputs() -> None:
    assert len(RADII_M) == 4
    assert abs(THICKNESS_M / N_LAYERS - 0.0006) < 1e-15
    expected_degrees = (17.1887, 42.9718, 57.2958, 85.9437)
    actual = tuple(math.degrees(ARC_LENGTH_M / radius) for radius in RADII_M)
    assert all(abs(a - b) < 1e-4 for a, b in zip(actual, expected_degrees, strict=True))
    assert PRESSURE_PA == 15_000.0
    assert ELECTRIC_LAYER_SPAN_V == 300.0
    assert MAGNETIC_LAYER_SPAN_A == 200.0
    # The 2D pressure-panel arrows must be perpendicular to the displayed
    # circular cross-section, not merely to an arc-length parameter axis.
    pressure_theta = np.linspace(0.0, ARC_LENGTH_M / 0.4, 9)
    tangent = np.column_stack((0.4 * np.cos(pressure_theta),
                               -0.4 * np.sin(pressure_theta)))
    inward = np.column_stack((-np.sin(pressure_theta),
                              -np.cos(pressure_theta)))
    assert np.max(np.abs(np.sum(tangent * inward, axis=1))) < 1e-14


def main() -> None:
    validate_inputs()
    apply_sci_style(base_size=8)
    mpl.rcParams.update({
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "axes.unicode_minus": False,
    })
    paths = geometry_figure() + material_load_figure()
    for path in paths:
        if not path.is_file() or path.stat().st_size <= 1_000:
            raise RuntimeError(f"Figure export failed: {path}")
        print(path)


if __name__ == "__main__":
    main()
