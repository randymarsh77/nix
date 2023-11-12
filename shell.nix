{ pkgs ? import (./.) { } }: with pkgs; mkShell { buildInputs = [ nixfmt ]; }
