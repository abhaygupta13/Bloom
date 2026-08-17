public class LeasingChargeMappingsUtil {
    private static LeasingChargeMappingsConfig config;
    private static LeasingChargeMappingsConfig getConfig() {
        if(config == null) {
            StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'leasingOCCatSubCatCTData' LIMIT 1];
            config = (LeasingChargeMappingsConfig)JSON.deserialize(sr.Body.toString(),LeasingChargeMappingsConfig.class);
        }
        return config;
    }
    public static Map<String,String> getTypeToConditionTypeMap() {
        return getConfig().typeToConditionTypeMap;
    }
    public static Map<String,String> getTypeToSubCategoryMap() {
        return getConfig().typeToSubCategoryMap;
    }
    public class LeasingChargeMappingsConfig {
        public Map<String,String> typeToConditionTypeMap;
        public Map<String,String> typeToSubCategoryMap;
    }
}