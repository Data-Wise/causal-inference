# If renv's project library lives in a synced folder (e.g., Dropbox),
# override the default library root to a local, non-synced location to
# avoid selective sync conflicts breaking installs.
if (Sys.getenv("RENV_PATHS_ROOT") == "") {
  Sys.setenv(RENV_PATHS_ROOT = file.path(Sys.getenv("HOME"), ".local/share/renv"))
}

source("renv/activate.R")
