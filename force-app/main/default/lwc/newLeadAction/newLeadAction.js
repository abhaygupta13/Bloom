import { LightningElement, track } from 'lwc';
import getSalutation from '@salesforce/apex/LeadController.getSalutation';
import getNationality from '@salesforce/apex/LeadController.getNationality';
import getMobileCountryCode from '@salesforce/apex/LeadController.getMobileCountryCode';
import getMaritalStatus from '@salesforce/apex/LeadController.getMaritalStatus';
import getGenderIdentity from '@salesforce/apex/LeadController.getGenderIdentity';
import createLeadFromEID from '@salesforce/apex/LeadController.createLeadFromEID';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class NewLeadAction extends NavigationMixin(LightningElement) {

    @track isShowModal = false;
    @track showLoading = false;

    @track saluation;
    @track firstName;
    @track middleName;
    @track lastName;
    @track fullNameInEnglish;
    @track fullNameInArabic;
    @track birthdate;
    @track gender;
    @track maritalStatus;
    @track mobileCountryCode;
    @track mobile;
    @track email;
    @track nationality;
    @track passport;
    @track passportExpiryDate;
    @track placeOfIssue;
    @track eid;
    @track eidExpiryDate;

    @track saluationList = [];
    @track genderList = [];
    @track nationalityList = [];
    @track maritalStatusList = [];
    @track mobileCountryCodeList = [];

    connectedCallback() {

    }

    handleOpenModal() {
        this.doGetSalutation();
        this.doGetGenderIdentity();
        this.doGetNationality();
        this.doGetMaritalStatus();
        this.doGetMobileCountryCode();
        this.isShowModal = true;
    }

    handleCloseModal() {
        this.isShowModal = false;
    }

    handleSave() {
        this.doCreateLeadFromEID();
    }

    handleSaluationChange(event) {
        this.saluation = event.target.value;
    }

    handleFirstNameChange(event) {
        this.firstName = event.target.value;
    }

    handleMiddleNameChange(event) {
        this.middleName = event.target.value;
    }

    handleLastNameChange(event) {
        this.lastName = event.target.value;
    }

    handleFullNameEngishChange(event) {
        this.fullNameEnglish = event.target.value;
    }

    handleFullNameArabicChange(event) {
        this.fullNameInArabic = event.target.value;
    }

    handleDOBChange(event) {
        this.birthdate = event.target.value;
    }

    handleGenderChange(event) {
        this.gender = event.target.value;
    }

    handleMaritalStatusChange(event) {
        this.maritalStatus = event.target.value;
    }

    handleMobileCountryCodeChange(event) {
        this.mobileCountryCode = event.target.value;
    }

    handleMobileChange(event) {
        this.mobile = event.target.value;
    }

    handleEmailChange(event) {
        this.email = event.target.value;
    }

    handleNationalityChange(event) {
        this.nationality = event.target.value;
    }

    handlePassportChange(event) {
        this.passport = event.target.value;
    }

    handlePassportExpiryDateChange(event) {
        this.passportExpiryDate = event.target.value;
    }

    handlePlaceOfIssueChange(event) {
        this.placeOfIssue = event.target.value;
    }

    handleEIDChange(event) {
        this.eid = event.target.value;
    }

    handleEIDExpiryDateChange(event) {
        this.eidExpiryDate = event.target.value;
    }

    doGetSalutation() {
        this.showLoading = true;
        getSalutation({}).then(result => {
            this.showLoading = false;
            if (result) {
                var saluationOptions = [];
                for (var key in result) {
                    saluationOptions.push({ value: key, label: result[key] });
                }
                this.saluationList = saluationOptions;
            }
        }).catch(error => {
            this.showLoading = false;
        });
    }

    doGetGenderIdentity() {
        this.showLoading = true;
        getGenderIdentity({}).then(result => {
            this.showLoading = false;
            if (result) {
                var genderOptions = [];
                for (var key in result) {
                    genderOptions.push({ value: key, label: result[key] });
                }
                this.genderList = genderOptions;
            }
        }).catch(error => {
            this.showLoading = false;
        });
    }

    doGetNationality() {
        this.showLoading = true;
        getNationality({}).then(result => {
            this.showLoading = false;
            if (result) {
                var nationalityOptions = [];
                for (var key in result) {
                    nationalityOptions.push({ value: key, label: result[key] });
                }
                this.nationalityList = nationalityOptions;
            }
        }).catch(error => {
            this.showLoading = false;
        });
    }

    doGetMaritalStatus() {
        this.showLoading = true;
        getMaritalStatus({}).then(result => {
            this.showLoading = false;
            if (result) {
                var maritalStatusOptions = [];
                for (var key in result) {
                    maritalStatusOptions.push({ value: key, label: result[key] });
                }
                this.maritalStatusList = maritalStatusOptions;
            }
        }).catch(error => {
            this.showLoading = false;
        });
    }

    doGetMobileCountryCode() {
        this.showLoading = true;
        getMobileCountryCode({}).then(result => {
            this.showLoading = false;
            if (result) {
                var mobileCountryCodeOptions = [];
                for (var key in result) {
                    mobileCountryCodeOptions.push({ value: key, label: result[key] });
                }
                this.mobileCountryCodeList = mobileCountryCodeOptions;
            }
        }).catch(error => {
            this.showLoading = false;
        });
    }

    doCreateLeadFromEID() {
        this.showLoading = true;
        createLeadFromEID({
            saluation: this.saluation, firstName: this.firstName, middleName: this.middleName,
            lastName: this.lastName, fullNameInArabic: this.fullNameInArabic, birthdate: this.birthdate,
            gender: this.gender, maritalStatus: this.maritalStatus, mobileCountryCode: this.mobileCountryCode,
            mobile: this.mobile, email: this.email, nationality: this.nationality,
            passport: this.passport, passportExpiryDate: this.passportExpiryDate, placeOfIssue: this.placeOfIssue,
            eid: this.eid, eidExpiryDate: this.eidExpiryDate
        }).then(result => {
            this.showLoading = false;
            if (result) {
                this.showSuccessMessage('Lead was created successfully.');
                this.navigateToLeadRecord(result);
            }
        }).catch(error => {
            this.showLoading = false;
            var message;
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showErrorMessage(JSON.stringify(message));
        });
    }

    showErrorMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    showSuccessMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: msg,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    navigateToLeadRecord(leadId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: leadId,
                actionName: 'view'
            }
        });
    }
}