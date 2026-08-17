@istest
public class ContentServiceTest {
    @istest
    static void TestMethod1(){
        String Base64 = 'ajsadjsadhdoqddkjsadnkjsanwjqndnwdnanw2213211232';
        String fileName = 'Test File';
        String title = 'Test Title';
        Test.startTest();
         ContentService objContentService = ContentService.getInstance();
        objContentService.createContentVersion(Base64,fileName,title);
        Test.stopTest();
    }
    
    @isTest
    static void testContentVersionMethods() {
        // Arrange: Prepare test data
        Blob testBlob = Blob.valueOf('Sample file content');
        String fileName = 'TestFile.txt';
        String title = 'Test Title';

        // Test: createContentVersion (Single)
        ContentService utility = ContentService.getInstance();
        ContentVersion cv = utility.createContentVersion(testBlob, fileName, title);

        System.assertNotEquals(null, cv.Id, 'ContentVersion should be created and have an ID.');
        ContentVersion insertedCV = [SELECT Id, Title, PathOnClient, VersionData FROM ContentVersion WHERE Id = :cv.Id];
        System.assertEquals(title, insertedCV.Title, 'Title should match the input.');
        System.assertEquals(fileName, insertedCV.PathOnClient, 'File name should match the input.');
        
        // Test: createContentVersion (Batch)
        List<ContentVersion> cvList = new List<ContentVersion>{
            new ContentVersion(VersionData = testBlob, Title = 'BatchFile1', PathOnClient = 'BatchFile1.txt', IsMajorVersion = true),
            new ContentVersion(VersionData = testBlob, Title = 'BatchFile2', PathOnClient = 'BatchFile2.txt', IsMajorVersion = true)
        };
        Test.startTest();
        List<ContentVersion> createdCVs = utility.createContentVersion(cvList);
        Test.stopTest();

        System.assertEquals(2, createdCVs.size(), 'Two ContentVersion records should be created.');

        // Test: getContentDocumentId
        Id contentDocumentId = utility.getContentDocumentId(cv.Id);
        System.assertNotEquals(null, contentDocumentId, 'ContentDocumentId should be fetched.');

        // Test: getContentVersionsByCDIds
        Set<Id> cdIds = new Set<Id>{contentDocumentId};
        List<ContentVersion> latestCVs = utility.getContentVersionsByCDIds(cdIds);
        System.assertEquals(1, latestCVs.size(), 'Should return 1 latest ContentVersion for the ContentDocument.');

        // Test: getContentVersionByIds
        List<ContentVersion> fetchedCVs = utility.getContentVersionByIds(new List<ContentVersion>{cv});
        System.assertEquals(1, fetchedCVs.size(), 'Should return 1 ContentVersion record for the given ID.');

        // Test: getContentPubicURL
        ContentDistribution cd = utility.createContentDistribution(cv.Id, 'Public Link Test');
        String publicUrl = utility.getContentPubicURL(cd.Id);
        System.assertNotEquals(null, publicUrl, 'Public URL should be fetched.');

        // Test: deleteContentDocuments
        List<ContentDocument> toDelete = [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
        utility.deleteContentDocuments(toDelete);
        System.assertEquals(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :contentDocumentId], 'ContentDocument should be deleted.');
    }

}