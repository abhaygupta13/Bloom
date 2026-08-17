global with sharing class SyncUtil {
    public SyncUtil(Object o) {}

    @RemoteAction
    global static boolean isSyncEnable() {
        return true;
    }
}