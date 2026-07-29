import os

path_kts = "android/app/build.gradle.kts"
path_groovy = "android/app/build.gradle"

if os.path.exists(path_kts):
    path = path_kts
    is_kts = True
else:
    path = path_groovy
    is_kts = False

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

if is_kts:
    if "isCoreLibraryDesugaringEnabled" not in content:
        content = content.replace(
            "compileOptions {",
            "compileOptions {\n        isCoreLibraryDesugaringEnabled = true",
            1,
        )
    if "coreLibraryDesugaring(" not in content:
        if "\ndependencies {" in content:
            content = content.replace(
                "\ndependencies {",
                '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")',
                1,
            )
        else:
            content += (
                '\n\ndependencies {\n'
                '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n'
                '}\n'
            )
else:
    if "coreLibraryDesugaringEnabled" not in content:
        content = content.replace(
            "compileOptions {",
            "compileOptions {\n        coreLibraryDesugaringEnabled true",
            1,
        )
    if "coreLibraryDesugaring " not in content:
        if "\ndependencies {" in content:
            content = content.replace(
                "\ndependencies {",
                "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'",
                1,
            )
        else:
            content += (
                "\n\ndependencies {\n"
                "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n"
                "}\n"
            )

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("Gradle dosyasi core library desugaring icin guncellendi:", path)
