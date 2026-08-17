public class ReportService {
	public static Map<Id, Report> getReportsFromFolder(String folderName) {
        Map<Id, Report> reportMap = new Map<Id, Report>();
        for (Report report : [
            SELECT CreatedById, CreatedDate, Description, DeveloperName, FolderName, Format, Id, Name, NamespacePrefix, OwnerId
            FROM Report
            WHERE FolderName = :folderName
        ]) {
            reportMap.put(report.Id, report);
        }
        return reportMap;
    }
}