"""Writes Utter.xcodeproj/project.pbxproj.

The project uses folder-synced groups (Xcode 16+), so new Swift files in
Shared/, Utter/, UtterKeyboard/ or UtterUITests/ are picked up without
editing the project. Run this only to change targets or build settings:
    python3 Tools/make_project.py
"""

def oid(n):
    return f"AA{n:022X}"

P = {k: oid(v) for k, v in dict(
    app_product=1, kb_product=2, ui_product=3,
    g_shared=0x10, g_app=0x11, g_kb=0x12, g_ui=0x13, g_config=0x14,
    f_app_plist=0x15, f_kb_plist=0x16, f_app_ent=0x17, f_kb_ent=0x18,
    g_main=0x20, g_products=0x21,
    t_app=0x30, t_kb=0x31, t_ui=0x32,
    app_src=0x40, app_fw=0x41, app_res=0x42, app_embed=0x43,
    kb_src=0x44, kb_fw=0x45, kb_res=0x46,
    ui_src=0x47, ui_fw=0x48, ui_res=0x49,
    bf_embed=0x50,
    proxy_kb=0x60, proxy_app=0x61, dep_kb=0x62, dep_app=0x63,
    project=0x70, cl_project=0x71, cl_app=0x72, cl_kb=0x73, cl_ui=0x74,
    c_proj_d=0x80, c_proj_r=0x81, c_app_d=0x82, c_app_r=0x83, c_kb_d=0x84, c_kb_r=0x85, c_ui_d=0x86, c_ui_r=0x87,
).items()}


def settings(d, indent="\t\t\t\t"):
    out = []
    for k in sorted(d):
        v = d[k]
        if isinstance(v, list):
            out.append(f"{indent}{k} = (")
            for item in v:
                out.append(f"{indent}\t{q(item)},")
            out.append(f"{indent});")
        else:
            out.append(f"{indent}{k} = {q(v)};")
    return "\n".join(out)


def q(v):
    v = str(v)
    if v and all(c.isalnum() or c in "._/" for c in v):
        return v
    return '"' + v.replace('\\', '\\\\').replace('"', '\\"') + '"'


project_common = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_ENABLE_OBJC_WEAK": "YES",
    "COPY_PHASE_STRIP": "NO",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_NO_COMMON_BLOCKS": "YES",
    # iOS 26 brings Apple's on-device speech engine and language model.
    "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
    "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
    "MTL_FAST_MATH": "YES",
    "SDKROOT": "iphoneos",
    # Change this one line if Xcode says the bundle id is taken; the app,
    # keyboard and App Group ids all follow it.
    "UTTER_BUNDLE_PREFIX": "com.albertoaday",
    "APP_GROUP": "group.$(UTTER_BUNDLE_PREFIX).utter",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1",
}
proj_debug = dict(project_common, **{
    "DEBUG_INFORMATION_FORMAT": "dwarf", "ENABLE_TESTABILITY": "YES", "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_OPTIMIZATION_LEVEL": "0", "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE", "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)", "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
})
proj_release = dict(project_common, **{
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym", "ENABLE_NS_ASSERTIONS": "NO",
    "MTL_ENABLE_DEBUG_INFO": "NO", "SWIFT_COMPILATION_MODE": "wholemodule", "VALIDATE_PRODUCT": "YES",
})
app = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_ENTITLEMENTS": "Config/Utter.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_FILE": "Config/Utter-Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName": "Utter",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.productivity",
    "INFOPLIST_KEY_NSMicrophoneUsageDescription": "Utter listens only after you tap its mic, turns your speech into text on this iPhone, and stops after a minute of quiet.",
    "INFOPLIST_KEY_NSSpeechRecognitionUsageDescription": "Utter turns your speech into text on this iPhone. Nothing is sent anywhere.",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "$(UTTER_BUNDLE_PREFIX).utter",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
}
kb = {
    "APPLICATION_EXTENSION_API_ONLY": "YES",
    "CODE_SIGN_ENTITLEMENTS": "Config/UtterKeyboard.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_FILE": "Config/UtterKeyboard-Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName": "Utter",
    "INFOPLIST_KEY_NSHumanReadableCopyright": "",
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks"],
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "$(UTTER_BUNDLE_PREFIX).utter.keyboard",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SKIP_INSTALL": "YES",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
}
ui = {
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "GENERATE_INFOPLIST_FILE": "YES",
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "$(UTTER_BUNDLE_PREFIX).utter.uitests",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SWIFT_EMIT_LOC_STRINGS": "NO",
    "TEST_TARGET_NAME": "Utter",
}


def config(i, name, s):
    return f"""\t\t{P[i]} /* {name} */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
{settings(s)}
\t\t\t}};
\t\t\tname = {name};
\t\t}};"""


def conf_list(i, comment, d, r):
    return f"""\t\t{P[i]} /* {comment} */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{P[d]} /* Debug */,
\t\t\t\t{P[r]} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};"""


def phase(i, isa, name, extra=""):
    return f"""\t\t{P[i]} /* {name} */ = {{
\t\t\tisa = {isa};
\t\t\tbuildActionMask = 2147483647;
{extra}\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};"""


def target(i, name, cl, phases, deps, groups, product, ptype):
    ph = "\n".join(f"\t\t\t\t{P[p]}," for p in phases)
    dp = "\n".join(f"\t\t\t\t{P[d]} /* PBXTargetDependency */," for d in deps)
    gr = "\n".join(f"\t\t\t\t{P[g]}," for g in groups)
    return f"""\t\t{P[i]} /* {name} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {P[cl]};
\t\t\tbuildPhases = (
{ph}
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
{dp}
\t\t\t);
\t\t\tfileSystemSynchronizedGroups = (
{gr}
\t\t\t);
\t\t\tname = {name};
\t\t\tpackageProductDependencies = (
\t\t\t);
\t\t\tproductName = {name};
\t\t\tproductReference = {P[product]};
\t\t\tproductType = "{ptype}";
\t\t}};"""


embed_phase = f"""\t\t{P['app_embed']} /* Embed Foundation Extensions */ = {{
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 13;
\t\t\tfiles = (
\t\t\t\t{P['bf_embed']} /* UtterKeyboard.appex in Embed Foundation Extensions */,
\t\t\t);
\t\t\tname = "Embed Foundation Extensions";
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};"""

text = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 77;
\tobjects = {{

/* Begin PBXBuildFile section */
\t\t{P['bf_embed']} /* UtterKeyboard.appex in Embed Foundation Extensions */ = {{isa = PBXBuildFile; fileRef = {P['kb_product']} /* UtterKeyboard.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
\t\t{P['proxy_kb']} = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {P['project']};
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {P['t_kb']};
\t\t\tremoteInfo = UtterKeyboard;
\t\t}};
\t\t{P['proxy_app']} = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {P['project']};
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {P['t_app']};
\t\t\tremoteInfo = Utter;
\t\t}};
/* End PBXContainerItemProxy section */

/* Begin PBXCopyFilesBuildPhase section */
{embed_phase}
/* End PBXCopyFilesBuildPhase section */

/* Begin PBXFileReference section */
\t\t{P['app_product']} /* Utter.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Utter.app; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{P['kb_product']} /* UtterKeyboard.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = UtterKeyboard.appex; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{P['ui_product']} /* UtterUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = UtterUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{P['f_app_plist']} = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "Utter-Info.plist"; sourceTree = "<group>"; }};
\t\t{P['f_kb_plist']} = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "UtterKeyboard-Info.plist"; sourceTree = "<group>"; }};
\t\t{P['f_app_ent']} = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Utter.entitlements; sourceTree = "<group>"; }};
\t\t{P['f_kb_ent']} = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = UtterKeyboard.entitlements; sourceTree = "<group>"; }};
/* End PBXFileReference section */

/* Begin PBXFileSystemSynchronizedRootGroup section */
\t\t{P['g_shared']} /* Shared */ = {{isa = PBXFileSystemSynchronizedRootGroup; path = Shared; sourceTree = "<group>"; }};
\t\t{P['g_app']} /* Utter */ = {{isa = PBXFileSystemSynchronizedRootGroup; path = Utter; sourceTree = "<group>"; }};
\t\t{P['g_kb']} /* UtterKeyboard */ = {{isa = PBXFileSystemSynchronizedRootGroup; path = UtterKeyboard; sourceTree = "<group>"; }};
\t\t{P['g_ui']} /* UtterUITests */ = {{isa = PBXFileSystemSynchronizedRootGroup; path = UtterUITests; sourceTree = "<group>"; }};
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXFrameworksBuildPhase section */
{phase('app_fw', 'PBXFrameworksBuildPhase', 'Frameworks')}
{phase('kb_fw', 'PBXFrameworksBuildPhase', 'Frameworks')}
{phase('ui_fw', 'PBXFrameworksBuildPhase', 'Frameworks')}
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{P['g_main']} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{P['g_shared']} /* Shared */,
\t\t\t\t{P['g_app']} /* Utter */,
\t\t\t\t{P['g_kb']} /* UtterKeyboard */,
\t\t\t\t{P['g_ui']} /* UtterUITests */,
\t\t\t\t{P['g_config']} /* Config */,
\t\t\t\t{P['g_products']} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{P['g_config']} /* Config */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{P['f_app_plist']},
\t\t\t\t{P['f_kb_plist']},
\t\t\t\t{P['f_app_ent']},
\t\t\t\t{P['f_kb_ent']},
\t\t\t);
\t\t\tpath = Config;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{P['g_products']} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{P['app_product']} /* Utter.app */,
\t\t\t\t{P['kb_product']} /* UtterKeyboard.appex */,
\t\t\t\t{P['ui_product']} /* UtterUITests.xctest */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
{target('t_app', 'Utter', 'cl_app', ['app_src', 'app_fw', 'app_res', 'app_embed'], ['dep_kb'], ['g_shared', 'g_app'], 'app_product', 'com.apple.product-type.application')}
{target('t_kb', 'UtterKeyboard', 'cl_kb', ['kb_src', 'kb_fw', 'kb_res'], [], ['g_shared', 'g_kb'], 'kb_product', 'com.apple.product-type.app-extension')}
{target('t_ui', 'UtterUITests', 'cl_ui', ['ui_src', 'ui_fw', 'ui_res'], ['dep_app'], ['g_ui'], 'ui_product', 'com.apple.product-type.bundle.ui-testing')}
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{P['project']} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 2710;
\t\t\t\tLastUpgradeCheck = 2710;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{P['t_app']} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 27.1;
\t\t\t\t\t}};
\t\t\t\t\t{P['t_kb']} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 27.1;
\t\t\t\t\t}};
\t\t\t\t\t{P['t_ui']} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 27.1;
\t\t\t\t\t\tTestTargetID = {P['t_app']};
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {P['cl_project']};
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tes,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {P['g_main']};
\t\t\tminimizedProjectReferenceProxies = 1;
\t\t\tpreferredProjectObjectVersion = 77;
\t\t\tproductRefGroup = {P['g_products']} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{P['t_app']} /* Utter */,
\t\t\t\t{P['t_kb']} /* UtterKeyboard */,
\t\t\t\t{P['t_ui']} /* UtterUITests */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
{phase('app_res', 'PBXResourcesBuildPhase', 'Resources')}
{phase('kb_res', 'PBXResourcesBuildPhase', 'Resources')}
{phase('ui_res', 'PBXResourcesBuildPhase', 'Resources')}
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
{phase('app_src', 'PBXSourcesBuildPhase', 'Sources')}
{phase('kb_src', 'PBXSourcesBuildPhase', 'Sources')}
{phase('ui_src', 'PBXSourcesBuildPhase', 'Sources')}
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
\t\t{P['dep_kb']} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {P['t_kb']} /* UtterKeyboard */;
\t\t\ttargetProxy = {P['proxy_kb']};
\t\t}};
\t\t{P['dep_app']} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {P['t_app']} /* Utter */;
\t\t\ttargetProxy = {P['proxy_app']};
\t\t}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
{config('c_proj_d', 'Debug', proj_debug)}
{config('c_proj_r', 'Release', proj_release)}
{config('c_app_d', 'Debug', app)}
{config('c_app_r', 'Release', app)}
{config('c_kb_d', 'Debug', kb)}
{config('c_kb_r', 'Release', kb)}
{config('c_ui_d', 'Debug', ui)}
{config('c_ui_r', 'Release', ui)}
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
{conf_list('cl_project', 'Build configuration list for PBXProject "Utter"', 'c_proj_d', 'c_proj_r')}
{conf_list('cl_app', 'Build configuration list for PBXNativeTarget "Utter"', 'c_app_d', 'c_app_r')}
{conf_list('cl_kb', 'Build configuration list for PBXNativeTarget "UtterKeyboard"', 'c_kb_d', 'c_kb_r')}
{conf_list('cl_ui', 'Build configuration list for PBXNativeTarget "UtterUITests"', 'c_ui_d', 'c_ui_r')}
/* End XCConfigurationList section */
\t}};
\trootObject = {P['project']} /* Project object */;
}}
"""
open("Utter.xcodeproj/project.pbxproj", "w").write(text)

scheme = open("Tools/scheme-template.xml").read()
scheme = (scheme.replace("@APP@", P['t_app']).replace("@UI@", P['t_ui']))
open("Utter.xcodeproj/xcshareddata/xcschemes/Utter.xcscheme", "w").write(scheme)
print("wrote Utter.xcodeproj")
