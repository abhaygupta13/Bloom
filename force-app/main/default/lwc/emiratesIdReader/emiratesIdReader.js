import { LightningElement, track, wire, api } from 'lwc';
import getDuplicateAccount from '@salesforce/apex/EmirateIdReaderHandler.getAccountByDocumentAndEmirateId';
import createPersonAccount from '@salesforce/apex/EmirateIdReaderHandler.createPersonAccount';
import createOpportunity from '@salesforce/apex/EmirateIdReaderHandler.createOpportunity';
import updatePersonAccount from '@salesforce/apex/EmirateIdReaderHandler.updateAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPicklistvalue from "@salesforce/apex/Utilities.getPicklistValues";
import { NavigationMixin } from 'lightning/navigation';

export default class OcrAccountCreation extends NavigationMixin(LightningElement) {

  @track accountfieldList = [];
  firstName
  salutation
  salutationValues
  lastName
  middleName
  fullNameEnglish
  mobileCountrycodeValues
  mobileCountryCode
  dob
  gender
  idNumber
  expiryNumber
  enquiryDate
  homeMobile
  homeEmail

  titleArabic
  fullNameArabic
  nationalityEnglish
  passport
  passportCountry
  passportExpiryDate
  placeOfBirthEnglish
  phone
  Occupation
  company
  martialStatus
  martialStatusValues
  qualification
  address
  mailingCountry
  mailingCountryValues
  mailingStreet
  mailingPostalcode
  mailingState
  mailingSateValues
  mailingCity
  nationality
  genderValues
  reigionValues
  religion
  customerTypevalues
  customerTypeValue
  customerSubTypeValues
  customerSubtype
  noOfYearsEmployed
  postion
  annualIncome
  crateWalkInOpportunity
  firstPurchased
  noOfPropertiesOwned
  purposeOfUse
  residentStatus
  residentStatusValues
  AnniversaryDate
  BrokerAgency
  createBrokerOpportunity
  noOfChildren
  currentHomeStatusValues
  currentHomeStatus
  placeofIssue
  purposeofUseValues
  lookupBrokerid
  lookupAccountBrokerId

  @track createWalkinOpportunity = false;
  @track isDuplicateEligible = false;
  @track AccountResult;
  @track showAccountResult = false;
  @track showNavigateButton = false;
  @track showCreatAccount = true;
  @track recordIdOrg;
  @track showCreatDuplicateAccount = false;
  @track showErrorMessage = false;



  @wire(getPicklistvalue, {
    objName: 'Account',
    fieldName: 'Salutation'
  })
  wiredSalutaionValues({ data, error }) {
    if (data) {
      let temp = [];

      for (var key in data) {
        temp.push({ label: key, value: data[key] });
      }
      this.salutationValues = temp;

    } else if (error) {
      console.log('error' + JSON.stringify(error));
      this.error = error;
      this.salutationValues = undefined;
    }
  }

  @wire(getPicklistvalue, {
    objName: 'Account',
    fieldName: 'MobileCountryCode__pc'
  })
  wiredMobileCountrycode({ data, error }) {
    if (data) {
      let temp = [];

      for (var key in data) {
        temp.push({ label: key, value: data[key] });
      }
      this.mobileCountrycodeValues = temp;

    } else if (error) {
      console.log('error' + JSON.stringify(error));
      this.error = error;
      this.mobileCountrycodeValues = undefined;
    }
  }
 /* 
  @wire(getPicklistvalue, {
    objName: 'Account',
    fieldName: 'Nationality__pc'
  })
 wiredNationalityValues({ data, error }) {
    if (data) {
      let temp = [];

      for (var key in data) {
        temp.push({ label: key, value: data[key] });
      }
      this.nationality = temp;

    } else if (error) {
      console.log('error' + JSON.stringify(error));
      this.error = error;
      this.nationality = undefined;
    }
  }

  @wire(getPicklistvalue, {
    objName: 'Account',
    fieldName: 'PersonMailingCountry'
  })
  wiredmailingCountryValues({ data, error }) {
    if (data) {

      let temp = [];

      for (var key in data) {
        temp.push({ label: key, value: data[key] });
      }
      this.mailingCountryValues = temp;

    } else if (error) {
      console.log('error' + JSON.stringify(error));
      this.error = error;
      this.mailingCountryValues = undefined;
    }
  }
 

  @wire(getPicklistvalue, {
    objName: 'Account',
    fieldName: 'Gender__pc'
  })
  wiredGenderValues({ data, error }) {
    if (data) {
      let temp = [];

      for (var key in data) {
        temp.push({ label: key, value: data[key] });
      }
      this.genderValues = temp;
      console.log(JSON.stringify(this.bankNames));
    } else if (error) {
      console.log('error' + JSON.stringify(error));
      this.error = error;
      this.genderValues = undefined;
    }
  }
*/
  @wire(getPicklistvalue, {
    objName: 'Account',
    fieldName: 'Religion__pc'
  })
  wiredReligionValues({ data, error }) {
    if (data) {
      let temp = [];

      for (var key in data) {
        temp.push({ label: key, value: data[key] });
      }
      this.reigionValues = temp;

    } else if (error) {
      console.log('error' + JSON.stringify(error));
      this.error = error;
      this.reigionValues = undefined;
    }
  }

  @wire(getPicklistvalue, {
    objName: 'Account',
    fieldName: 'MaritalStatus__pc'
  })
  wiredMartialStatusvalues({ data, error }) {
    if (data) {
      let temp = [];

      for (var key in data) {
        temp.push({ label: key, value: data[key] });
      }
      this.martialStatusValues = temp;

    } else if (error) {
      console.log('error' + JSON.stringify(error));
      this.error = error;
      this.martialStatusValues = undefined;
    }
  }

  @wire(getPicklistvalue, {
    objName: 'Account',
    fieldName: 'CustomerType__c'
  })
  wiredCustomTypeValues({ data, error }) {
    if (data) {
      let temp = [];

      for (var key in data) {
        temp.push({ label: key, value: data[key] });
      }
      this.customerTypevalues = temp;

    } else if (error) {
      console.log('error' + JSON.stringify(error));
      this.error = error;
      this.customerTypevalues = undefined;
    }
  }

  @wire(getPicklistvalue, {
    objName: 'Account',
    fieldName: 'CustomerSubType__c'
  })
  wiredCustomerSubTypevalues({ data, error }) {
    if (data) {
      let temp = [];

      for (var key in data) {
        temp.push({ label: key, value: data[key] });
      }
      this.customerSubTypeValues = temp;

    } else if (error) {
      console.log('error' + JSON.stringify(error));
      this.error = error;
      this.customerSubTypeValues = undefined;
    }
  }

  @wire(getPicklistvalue, {
    objName: 'Account',
    fieldName: 'ResidentStatus__pc'
  })
  wiredResidentStatusValues({ data, error }) {
    if (data) {
      let temp = [];

      for (var key in data) {
        temp.push({ label: key, value: data[key] });
      }
      this.residentStatusValues = temp;

    } else if (error) {
      console.log('error' + JSON.stringify(error));
      this.error = error;
      this.residentStatusValues = undefined;
    }
  }

  @wire(getPicklistvalue, {
    objName: 'Account',
    fieldName: 'CurrentHome__c'
  })
  wiredCurrentHomeStatusValues({ data, error }) {
    if (data) {
      let temp = [];

      for (var key in data) {
        temp.push({ label: key, value: data[key] });
      }
      this.currentHomeStatusValues = temp;

    } else if (error) {
      console.log('error' + JSON.stringify(error));
      this.error = error;
      this.currentHomeStatusValues = undefined;
    }
  }

  @wire(getPicklistvalue, {
    objName: 'Account',
    fieldName: 'Purpose_of_Use__c'
  })
  wiredPurposeOfUseValues({ data, error }) {
    if (data) {

      let temp = [];

      for (var key in data) {
        temp.push({ label: key, value: data[key] });
      }
      this.purposeofUseValues = temp;

    } else if (error) {
      console.log('error' + JSON.stringify(error));
      this.error = error;
      this.purposeofUseValues = undefined;
    }
  }


  handleChange(event) {

  }



  handleBlur(event) {

    if (event.target.label == 'Last Name') {
      this.lastName = event.target.value;

    }
    else if (event.target.label === 'Salutation') {
      this.salutation = event.target.value;
    }
    else if (event.target.label == 'Mobile Country Code') {
      this.mobileCountryCode = event.target.value;
    }
    else if (event.target.label == 'First Name') {
      this.firstName = event.target.value;
    }

    else if (event.target.label == 'Middle Name') {
      this.middleName = event.target.value;
    }
    else if (event.target.label == 'Full Name in English') {
      this.fullNameEnglish = event.target.value;
    }
    else if (event.target.label == 'Birthdate') {
      this.dob = event.target.value;
    }

    else if (event.target.label == 'Emirates ID #') {
      this.idNumber = event.target.value.replace(/[-\s]/g, '');
      console.log('id number' + this.idNumber);
    }

    else if (event.target.label == 'Gender') {
      this.gender = event.target.value;
    }
    else if (event.target.label == 'EID Expiry Date') {
      this.expiryDate = event.target.value;
    }
    else if (event.target.label == 'Mobile') {
      this.homeMobile = event.target.value;
      console.log('homemobile' + this.homeMobile);
    }
    else if (event.target.label == 'Email') {

      this.homeEmail = event.target.value;
    }

    else if (event.target.label == 'Title Arabic') {
      this.titleArabic = event.target.value;
    }
    else if (event.target.label == 'Full Name in Arabic') {
      this.fullNameArabic = event.target.value;
    }
    else if (event.target.label == 'Nationality') {
      this.nationalityEnglish = event.target.value;
    }
    else if (event.target.label == 'Passport') {
      this.passport = event.target.value;
    }

    else if (event.target.label == 'Passport Expiry Date') {
      this.passportExpiryDate = event.target.value;
    }
    else if (event.target.label == 'Place of Birth English') {
      this.placeOfBirthEnglish = event.target.value;
    }
    else if (event.target.label == 'Place of Issue') {
      this.placeofIssue = event.target.value;
    }
    else if (event.target.label == 'Phone') {
      this.phone = event.target.value;
    }
    else if (event.target.label == 'Position') {
      this.Occupation = event.target.value;
    }
    else if (event.target.label == 'Company') {
      this.company = event.target.value;
    }
    else if (event.target.label == 'Marital Status') {
      this.martialStatus = event.target.value;
    }
    else if (event.target.label == 'Qualification') {
      this.qualification = event.target.value;
    }
    else if (event.target.label == 'Address') {
      this.address = event.target.value;
    }
    else if (event.target.label == 'Mailing Country') {
      this.mailingCountry = event.target.value;
    }
    else if (event.target.label == 'Mailing Street') {
      this.mailingStreet = event.target.value;
    }
    else if (event.target.label == 'Mailing City') {
      this.mailingCity = event.target.value;
    }
    else if (event.target.label == 'Mailing State/Province') {
      this.mailingState = event.target.value;
    }
    else if (event.target.label == 'Mailing Zip/Postal Code') {
      this.mailingPostalcode = event.target.value;
    }
    else if (event.target.label == 'No of Years Employed') {
      this.noOfYearsEmployed = event.target.value;
    }
    else if (event.target.label == 'Customer Type') {
      this.customerTypeValue = event.target.value;
    }
    else if (event.target.label == 'Customer Sub Type') {
      this.customerSubtype = event.target.value;
    }
    else if (event.target.label == 'Annual Income') {
      this.annualIncome = event.target.value;
    }
    else if (event.target.label == 'Create Walk In Opportunity') {
      this.createWalkinOpportunity = event.target.checked;
    }
    else if (event.target.label == 'First Purchase') {
      this.firstPurchased = event.target.checked;
    }
    else if (event.target.label == 'No of Properties Owned') {
      this.noOfPropertiesOwned = event.target.value;
    }

    else if (event.target.label == 'Resident Status') {
      this.residentStatus = event.target.value;
    }
    else if (event.target.label == 'Anniversary Date') {
      this.AnniversaryDate = event.target.value;
    }
    else if (event.target.label == 'Religion') {
      this.religion = event.target.value;
    }
    else if (event.target.label == 'Religion') {
      this.religion = event.target.value;
    }
    else if (event.target.label == 'No of children') {
      this.noOfChildren = event.target.value;
    }
    else if (event.target.label == 'Current Home Status') {
      this.currentHomeStatus = event.target.value;
    }
    else if (event.target.label == 'Purpose of Use') {
      this.purposeofUse = event.target.value;
    }
    else if (event.target.label == 'Create Broker Opportunity') {
      this.createBrokerOpportunity = event.target.checked;
    }


  }

  handleLookupSelection(event) {

    this.lookupBrokerid = event.detail.selectedRecord.Id;
    console.log('lookupBrokerid' + this.lookupBrokerid);

  }
  handleLookupAccount(event) {

    this.lookupAccountBrokerId = event.detail.selectedRecord.Id;
    console.log('lookupBrokerid' + JSON.stringify(this.lookupAccountBrokerId));
  }

  CreateAccount() {
    this.isLoading = true;
    let obj = new Object();
    obj.sobjectType = 'Account';
    obj.FirstName = this.firstName;
    obj.Salutation = this.salutation;
    obj.MiddleName = this.middleName;
    obj.LastName = this.lastName;
    obj.NameinArabic__c = this.fullNameArabic;
    obj.EmirateExpirtyEidTExt__c = this.expiryDate;
    obj.GenderEIDReader_text__c = this.gender;
    obj.DobEidText__c = this.dob;
    obj.Emirates_Id__pc = this.idNumber;
    obj.NationalityEidText__c = this.nationalityEnglish;

    obj.PassportNumber__pc = this.passport;
    obj.PassportExpDateText__c = this.passportExpiryDate;
    obj.PersonHomePhone = this.phone;
    obj.Company__pc = this.company;
    obj.MaritalStatus__pc = this.martialStatus;
    obj.PersonMailingAddress = this.address;
    obj.Title_Arabic__c = this.titleArabic;
    obj.Place_of_Birth_English__c = this.placeOfBirthEnglish;
    obj.Qualification__c = this.qualification;
    obj.Position__pc = this.Occupation;
    obj.PlaceofIssue__pc = this.placeofIssue;
    obj.PersonMailingCity = this.mailingCity;
    obj.PersonMailingCountry = this.mailingCountry;
    obj.PersonMailingPostalCode = this.mailingPostalcode;
    obj.PersonMailingState = this.mailingPostalcode;
    obj.PersonMailingStreet = this.mailingStreet;
    obj.PersonEmail = this.homeEmail;
    obj.PersonMobilePhone = this.homeMobile;
    obj.MobileCountryCode__pc = this.mobileCountryCode;
    obj.No_of_Properties_Owned__c = this.noOfPropertiesOwned;
    obj.CreateOpportunity__c = this.createWalkinOpportunity;
    obj.Create_Broker_Opportunity__c = this.createBrokerOpportunity;
    obj.AnnualIncome__pc = this.annualIncome;
    obj.Religion__pc = this.religion;
    obj.Anniversary_Date__pc = this.AnniversaryDate;
    obj.ResidentStatus__pc = this.residentStatus;
    obj.CustomerSubType__c = this.customerSubtype;
    obj.CustomerType__c = this.customerTypeValue;
    obj.NoofYearswithCompany__pc = this.noOfYearsEmployed;
    obj.MaritalStatus__pc = this.martialStatus;
    obj.CurrentHome__c = this.currentHomeStatus;
    obj.No_of_Children__pc = this.noOfChildren;
    obj.First_Purchase__c = this.firstPurchased;

    obj.Purpose_of_Use__c = this.purposeofUse;
    obj.Create_Broker_Opportunity__c = this.createBrokerOpportunity;
    obj.BrokerAgent__c = this.lookupBrokerid;
    obj.Walk_In_Opportunity_Broker__c = this.lookupAccountBrokerId;




    console.log('obj' + JSON.stringify(obj));
    // alert(this.isDuplicateEligible);
    if (this.isDuplicateEligible != true) {
      getDuplicateAccount({ acc: obj })
        .then(result => {

          if (result.length > 0) {
            this.showCreatAccount = false;
            this.showCreatDuplicateAccount = true;
            this.showAccountResult = true;
            this.AccountResult = result;



            // this.accountId =result[0].Id;


          } else {
            this.showAccountResult = false;
          }



        }).catch(error => {
          this.error = error;

          console.log('error' + JSON.stringify(this.error.body));
          console.log('error' + JSON.stringify(this.error.body.message));
        })
    }

    createPersonAccount({
      acc: obj,
      isDuplicateEligible: this.isDuplicateEligible
    })
      .then(result => {
        if (result) {

          this.isLoading = false;
          this.showCreatAccount = false;
          this.showCreatDuplicateAccount = false;
          this.showLoading = false;
          this.showNavigateButton = true;
          this.recordIdOrg = result;
          console.log('recordIdOrg' + this.recordIdOrg);

          console.log('record Id:' + this.recordIdOrg);
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Success',
              variant: 'success',
              message: 'Person Account has been Created.',
            }),
          );


        }
      }).catch(error => {
        this.error = error;
        console.log('error' + this.error);
        this.isLoading = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'error',
            variant: 'error',
            message: error.body.message,
          }),
        );
      })
  }

  createDuplicateAccount() {
    this.isDuplicateEligible = true;
    this.CreateAccount();

  }

  navigateToAccount() {
    // Navigate to the newly created account
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.recordIdOrg, // Replace with your recordId
        objectApiName: 'Account', // Replace with the object you are navigating to
        actionName: 'view'
      }
    });
  }

  navigateToAccountRecord() {
    const accountId = event.target.dataset.id
    console.log('accounitId' + accountId);
    const url = '/lightning/r/Account/' + accountId + '/view';
    const win = window.open(url, '_blank');
    if (win) {
      // Browser has allowed it to be opened
      win.focus();
    } else {
      // Browser has blocked it

    }
  }




  handleSearch(event) {

    let obj = new Object();
    obj.sobjectType = 'Account';

    obj.Emirates_Id__pc = this.idNumber;
    obj.PersonEmail = this.homeEmail;
    obj.PersonMobilePhone = this.homeMobile;
    obj.PassportNumber__pc = this.passport;
    console.log('duplicate' + JSON.stringify(obj));
    this.isLoading = true
    getDuplicateAccount({ acc: obj })
      .then(result => {

        if (result.length > 0) {
          this.showErrorMessage = false;
          this.showAccountResult = true;
          this.AccountResult = result;
          console.log('this.AccountResult' + JSON.stringify(this.AccountResult));
        } else {
          this.showErrorMessage = true;
          this.showAccountResult = false;
        }
        this.isLoading = false;


      }).catch(error => {
        this.error = error;

        console.log('error' + JSON.stringify(this.error.body));
        console.log('error' + JSON.stringify(this.error.body.message));
      })
  }

  updateAccount() {
    const accountId = event.target.dataset.id
    console.log('accounitId' + accountId);
    this.isLoading = true;
    let obj = new Object();
     obj.sobjectType = 'Account';
    obj.FirstName = this.firstName;
    obj.Salutation = this.salutation;
    obj.MiddleName = this.middleName;
    obj.LastName = this.lastName;
    obj.NameinArabic__c = this.fullNameArabic;
    obj.EmirateExpirtyEidTExt__c = this.expiryDate;
    obj.GenderEIDReader_text__c = this.gender;
    obj.DobEidText__c = this.dob;
    obj.Emirates_Id__pc = this.idNumber;
    obj.NationalityEidText__c = this.nationalityEnglish;

    obj.PassportNumber__pc = this.passport;
    obj.PassportExpDateText__c = this.passportExpiryDate;
    obj.PersonHomePhone = this.phone;
    obj.Company__pc = this.company;
    obj.MaritalStatus__pc = this.martialStatus;
    obj.PersonMailingAddress = this.address;
    obj.Title_Arabic__c = this.titleArabic;
    obj.Place_of_Birth_English__c = this.placeOfBirthEnglish;
    obj.Qualification__c = this.qualification;
    obj.Position__pc = this.Occupation;
    obj.PlaceofIssue__pc = this.placeofIssue;
    obj.PersonMailingCity = this.mailingCity;
    obj.PersonMailingCountry = this.mailingCountry;
    obj.PersonMailingPostalCode = this.mailingPostalcode;
    obj.PersonMailingState = this.mailingPostalcode;
    obj.PersonMailingStreet = this.mailingStreet;
    obj.PersonEmail = this.homeEmail;
    obj.PersonMobilePhone = this.homeMobile;
    obj.MobileCountryCode__pc = this.mobileCountryCode;
    obj.No_of_Properties_Owned__c = this.noOfPropertiesOwned;
    obj.CreateOpportunity__c = this.createWalkinOpportunity;
    obj.Create_Broker_Opportunity__c = this.createBrokerOpportunity;
    obj.AnnualIncome__pc = this.annualIncome;
    obj.Religion__pc = this.religion;
    obj.Anniversary_Date__pc = this.AnniversaryDate;
    obj.ResidentStatus__pc = this.residentStatus;
    obj.CustomerSubType__c = this.customerSubtype;
    obj.CustomerType__c = this.customerTypeValue;
    obj.NoofYearswithCompany__pc = this.noOfYearsEmployed;
    obj.MaritalStatus__pc = this.martialStatus;
    obj.CurrentHome__c = this.currentHomeStatus;
    obj.No_of_Children__pc = this.noOfChildren;
    obj.First_Purchase__c = this.firstPurchased;

    obj.Purpose_of_Use__c = this.purposeofUse;
    obj.Create_Broker_Opportunity__c = this.createBrokerOpportunity;
    obj.BrokerAgent__c = this.lookupBrokerid;
    obj.Walk_In_Opportunity_Broker__c = this.lookupAccountBrokerId;

    this.isLoading = true;
    updatePersonAccount({ acc: obj, accountId: accountId })
      .then(result => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            variant: 'success',
            message: 'Person Account has been Updated.',
          }),
        );
        this.handleSearch();
        this.isLoading = false;

      }).catch(error => {
        this.error = error;
      })

  }
  createOpportunity(event) {
    const accountId = event.target.dataset.id;
    this.isLoading = true;
    
    createOpportunity({ accountId: accountId })
        .then(result => {
            if (result) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        variant: 'success',
                        message: 'Account Opportunity has been created successfully.',
                    })
                );
                
                const url = '/lightning/r/Opportunity/' + result + '/view';
                window.open(url, '_blank');
            } else {
                // Handle if result is null or undefined
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: 'Failed to create Opportunity.',
                    })
                );
            }
            this.isLoading = false;
        })
        .catch(error => {
            this.error = error;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: 'Error creating Opportunity: ' + error,
                })
            );
            this.isLoading = false;
        });
}

}