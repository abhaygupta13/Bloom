//============================ BCAPP_WrapperUtility =============================
/*
* @Author : Eagles
* @CreatedDate : 23rd OCT 2023 
* @Name : BCAPP_WrapperUtility
* @Description : All Wrapper Classes to handle mobile api request/response data
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               11NOV2023        Initial draft 
*****************************************************************************************************/


public class BCAPP_WrapperUtility {  
    
    public class TenantMoveInWrapper {
        public Request request { get; set; }
        public List<Document> documents { get; set; }
    }
    
    public class Request {
        public String srId { get; set; }
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String nationality { get; set; }
        public String emailAddress { get; set; }
        public String mobileNumber { get; set; }
        public String ejariStartDate { get; set; }
        public String ejariEndDate { get; set; }
        public String ejariNumber { get; set; }
        public String moveInDate { get; set; }
        public String emiratesNumber { get; set; }
        public String emiratesExpDate { get; set; }
        public String emergencyContactNumber01 { get; set; }
        public String emergencyContactNumber02 { get; set; }
        public Integer adultOccupants { get; set; }
        public Integer childOccupants { get; set; }
        public Boolean occupantsWithSpecialNeeds { get; set; }
        public String specialNeedsComments { get; set; }
        public String unitId { get; set; }
        public String requestAs { get; set; }
        public String requestType { get; set; }
        public Boolean hasAgreedTerms { get; set; }
        public Integer numberOfPets { get; set; }
    }
    
    
    public class HHOMoveInWrapper {
        public HHORequest request { get; set; }
        public List<Document> documents { get; set; }
    }
    
    public class HHORequest {
        public String srId { get; set; }
        public String representativeName { get; set; }
        public String operatorName { get; set; }
        public String representativeEmail { get; set; }
        public String representativeContactNumber { get; set; }
        public String operatorLicenseNumber { get; set; }
        public String operatorOfficeNumber { get; set; }
        public String operatorLicenseExpDate { get; set; }
        public String ejariStartDate { get; set; }
        public String ejariEndDate { get; set; }
        public String moveInDate { get; set; }
        public String emiratesIdNumber { get; set; }
        public String emiratesIdExpDate { get; set; }
        public String emergencyContactNumber01 { get; set; }
        public String emergencyContactNumber02 { get; set; }
        public String unitId { get; set; }
        public String requestAs { get; set; }
        public String requestType { get; set; }
        public String ejariNumber { get; set; }
        public Boolean hasAgreedTerms { get; set; }
        public Integer numberOfPets { get; set; }
    }
    
    public class Document {
        public String fileName { get; set; }
        public Blob fileContent { get; set; }
        public String contentType { get; set; }
    }
    
    
    public class serviceRequest {
        public String name { get; set; }
        public String imageURL { get; set; }
        public String srId { get; set; }
        public List<RequiredDocuments> documents;
    }
    /*   public class OwnerMoveInWrapper extends UserRequest{
public OwnerMoveInRequest request { get; set; }
public List<Document> documents { get; set; }
}*/
    
    public class OwnerMoveInWrapper extends UserRequest{
        public String srId { get; set; }
        public String moveInDate { get; set; }
        public String unitId { get; set; }
        public String emergencyContactNumber01 { get; set; }
        public String emergencyContactNumber02 { get; set; }
        public Integer adultOccupants { get; set; }
        public Integer childOccupants { get; set; }
        public Boolean occupantsWithSpecialNeeds { get; set; }
        public String specialNeedsComments { get; set; }
    }
    
    public class MyPortFolioResponse {
        public String unitNumber { get; set; }
        public Boolean unitBlocked { get; set; }
        public String floorNumber { get; set; }
        public String buildingName { get; set; }
        public String location { get; set; }
        public String unitId { get; set; }
        public String projectId { get; set; }
        public String projectName { get; set; }
        public Boolean isChillerEnabled { get; set; }
        public Boolean isLeaseHold { get; set; }
        public String communityImageURL{ get; set; }
        public Integer noOfGuests { get; set; }
        public String contractNo { get; set; }
        public String companyCode { get; set; }
    }
    
    public class TenantRenewWrapper extends UserRequest {
        public String leaseExpDate { get; set; }
        public String srId { get; set; }
        public String accountId { get; set; }
        public String unitId { get; set; }
        public String serviceCatalogId { get; set; }
        public String userType { get; set; }
        public Boolean hasAgreedTerms { get; set; }
        
        public Boolean hasOccupantWithSpecialNeeds { get; set; }
        public String occupantWithSpecialNeedsComments { get; set; }
        public Integer adultOccupants { get; set; }
        public Integer childOccupants { get; set; }
        public Integer numberOfPets { get; set; }
        
        public List<Document> documents { get; set; }
    }
    public class MoveOutWrapper extends UserRequest{
        public String srId { get; set; }
        public String moveOutDate { get; set; }
        public String accountId { get; set; }
        public String unitId { get; set; }
        public String serviceCatalogId { get; set; }
        public Boolean hasAgreedTerms { get; set; }
        public Integer numberOfPets { get; set; }
    }
    public class RequiredDocuments {
        public String Name { get; set; }
        public String displayName{ get; set; }
        public Integer documentSize{ get; set; }
        public List<String> documentType{ get; set; }
        public Boolean isRequired{ get; set; }
        public String sCatalogDocId{ get; set; }
        public String url{ get; set; }
        public String fileExtension{ get; set; }
        
    }
    public virtual class UserRequest {
        public String accountId;
    }
    public class Response {
        public Map<String,Object> response;
        public Response(){
            this.response = new Map<String,Object>();
        }
        public Response(Map<String,Object> response){
            this.response = response;
        }
    }
}