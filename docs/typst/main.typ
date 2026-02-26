// Docs: https://typst.app/docs

#import "template.typ": *

#show: project.with(
  title: "RO2 - Group 2",
  authors: ("A", "B", "C"),
)

// Cover
#grid(
  rows: (auto, 1fr, auto),
  grid(
    columns: (1fr),
    align: center + horizon,
    row-gutter: 15pt,
    text("Rechnerorganisation 2", size: 14pt),
    text("CPU Documentation", size: 22pt, weight: "bold"),
    text("Group 2", size: 14pt),
  ),
  align(horizon)[
    This document describes the design, implementation, and verification of our custom CPU developed as part of the RO2 course project. The goal was to collaboratively design a simple, yet functional CPU architecture, implement it in VHDL, and verify its operation through simulation.
  ],
  table(
    columns: (auto, auto, 1fr),
    "Name", "Matrikelnummer", "Email",
    "Berke Özmen", "3812619", link("mailto:st196187@stud.uni-stuttgart.de"),
    "Dominik Knaup", [3721438], link("mailto:st187468@stud.uni-stuttgart.de"),
    "Lukas Kurz", "3655410", link("mailto:st182338@stud.uni-stuttgart.de"),
    "Maximilian Rau", "3731389", link("mailto:st188391@stud.uni-stuttgart.de"),
    "Mouhammad Mahdi Bazzoun", [3743872], link("mailto:st189618@stud.uni-stuttgart.de"),
    "Muhammed Sahin", [3475535], link("mailto:st169152@stud.uni-stuttgart.de"),
  ),
)

= Architecture Overview

#include "architecture.typ"

= Component Descriptions

== Control Unit

#include "controlunit.typ"

#pagebreak()

== Data Path

#include "datapath.typ"

== Memory Unit

#include "memoryunit.typ"

== IO Unit

#include "io_unit.typ"

== Pipeline and Hazard Handling

#include "pipeline.typ"

= Instruction Set

#include "instructions.typ"

= Appendix

#include "appendix.typ"
