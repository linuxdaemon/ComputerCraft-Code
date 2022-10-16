
# git_repository(
    # name = "selene",
    # remote = "https://github.com/Vexatos/Selene.git"
# )

genrule(
    name = "selene_build_stats",
    srcs = [
        "init.sel"
    ],
    outs = ["init.lua"],
    cmd = "LUA_PATH='$(location @selene_repo//:selene)/lib/?/init.lua;$(location @selene_repo//:selene)/lib/?.lua;;' lua -l selene $(location //ci:build.lua) $(SRCS) > $(@)",
    tools = [
        "//ci:build.lua",
        "@selene_repo//:selene"
    ]
)