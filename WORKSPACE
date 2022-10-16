load("@bazel_tools//tools/build_defs/repo:git.bzl", "new_git_repository")

new_git_repository(
    name = "selene_repo",
    remote = "https://github.com/Vexatos/Selene.git",
    build_file_content = """
exports_files(["selene"])
    """,
    branch = "master"
)
