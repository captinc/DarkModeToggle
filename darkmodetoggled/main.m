#import <stdio.h>
#import <string.h>
#import <dlfcn.h>
#import "../NSTask.h"
#define FLAG_PLATFORMIZE (1 << 1)

void fixSetuidForChimera() { //on Chimera, you have to do this fancy stuff to make yourself root (cannot simply do setuid() like unc0ver/checkra1n)
    void *handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle) {
        return;
    }
    
    dlerror();
    typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
    fix_entitle_prt_t enetitle_ptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");
    const char *dlsym_error = dlerror();
    if (dlsym_error) {
        return;
    }
    enetitle_ptr(getpid(), FLAG_PLATFORMIZE);
    
    dlerror();
    typedef void (*fix_setuid_prt_t)(pid_t pid);
    fix_setuid_prt_t setuid_ptr = (fix_setuid_prt_t)dlsym(handle,"jb_oneshot_fix_setuid_now");
    dlsym_error = dlerror();
    if (dlsym_error) {
        return;
    }
    
    setuid_ptr(getpid());
    setuid(0);
    setgid(0);
    setuid(0);
    setgid(0);
}

int main(int argc, char *argv[], char *envp[]) { //runs the corresponding script as root for enabling/disabling DarkModeToggle
    if (argc < 2) {
        printf("Error: you must specify 'enableDarkMode' or 'disableDarkMode' to choose which corresponding script to run\n");
        return 1;
    }
    
    setuid(0); //make us root
    if (getuid() != 0) {
        fixSetuidForChimera();
    }
    
    NSString *scriptToRun;
    if (!strcmp(argv[1], "enableDarkMode")) {
        scriptToRun = @"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.enable.sh";
    }
    else {
        scriptToRun = @"/var/mobile/Library/Preferences/com.captinc.darkmodetoggle.disable.sh";
    }
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/bash";
    task.arguments = @[scriptToRun];
    [task launch];
    [task waitUntilExit];
    
    return 0;
}
