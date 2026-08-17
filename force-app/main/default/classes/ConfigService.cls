public class ConfigService {

    private static Map<String, String> terminationReasonMap;

    public static Map<String, String> getTerminationReasonMap() {

        if (terminationReasonMap == null) {

            StaticResource sr = [
                SELECT Body
                FROM StaticResource
                WHERE Name = 'LeasingOrderTerminationType'
                LIMIT 1
            ];

            terminationReasonMap =
                (Map<String, String>) JSON.deserialize(
                    sr.Body.toString(),
                    Map<String, String>.class
                );
        }

        return terminationReasonMap;
    }
}