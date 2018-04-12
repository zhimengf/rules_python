load("@io_bazel_rules_python//python:whl.bzl", _whl_library = "whl_library", "extract_wheels")

_buildtime_deps = {%{additional_buildtime_deps}
}
_runtime_deps = {%{additional_runtime_deps}
}

def _wheel(wheels_map, name):
  name_key = name.replace("-", "_").lower()
  name_key = name_key.split("[")[0] # Strip extra
  if name_key not in wheels_map:
    fail("Could not find wheel: '%s'" % name)
  return wheels_map[name_key]

def _wheels(wheels_map, names):
  return [_wheel(wheels_map, n) for n in names]

def whl_library(name, wheels_map={}, requirement=None, whl=None, whl_name=None, runtime_deps=[], extras=[]):
    dirty_name = "%s_dirty" % name
    key = requirement.split("==")[0]
    buildtime_deps = _buildtime_deps.get(key, [])
    additional_runtime_deps = _runtime_deps.get(key, [])
    if name not in native.existing_rules():
        if whl:
            extract_wheels(
                name = name,
                wheels = [whl],
                additional_runtime_deps = additional_runtime_deps,
                repository = "%{repo}",
                extras = extras,
            )
        else:
            _whl_library(
                name = name,
                dirty = False,
                requirement = requirement,
                repository = "%{repo}",
                buildtime_deps = _wheels(wheels_map, buildtime_deps),
                additional_runtime_deps = additional_runtime_deps,
                whl = whl,
                whl_name = whl_name,
                extras = extras,
                pip_args = [%{pip_args}],
            )

    if dirty_name not in native.existing_rules():
        extract_wheels(
            name = dirty_name,
            wheels = [_wheel(wheels_map, key)] + _wheels(wheels_map, runtime_deps),
            additional_runtime_deps = additional_runtime_deps,
            repository = "%{repo}",
            extras = extras,
        )
