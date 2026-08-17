import { LightningElement, track } from 'lwc';
import getNationality from '@salesforce/apex/AccountController.getNationality';
import getMobileCountryCode from '@salesforce/apex/AccountController.getMobileCountryCode';
import getRegistrationAuthority from '@salesforce/apex/AccountController.getRegistrationAuthority';
import getIndividualAccount from '@salesforce/apex/AccountController.getIndividualAccount';
import getOrganizationAccount from '@salesforce/apex/AccountController.getOrganizationAccount';
import createLeadFromAccount from '@salesforce/apex/LeadController.createLeadFromAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class AccountSearchAction extends NavigationMixin(LightningElement) {

    @track isShowModal = false;
    @track showLoading = false;

    @track showIndividualTab = false;
    @track showOrganisationTab = false;
    @track showByPassport = false;
    @track showByContact = false;
    @track showByEmail = false;
    @track showByLicence = false;
    @track showByLicenseNo = false;
    @track showByAuthority = false;
    @track showByEmiratesId = false;

    @track registrationAuthorityList = [];
    @track nationalityList = [];
    @track mobileCountryCodeList = [];

    @track accountResult = [];

    @track isDuplicateLead;
    @track isIndividualLead;
    @track isActionSuccess;
    @track recordIdOrg;

    @track emailAddress;
    @track mobileNumber;
    @track countryCode;
    @track passportNumber;
    @track nationality;
    @track emiratesId;
    @track licenseNo;
    @track authority;
    @track individualSearchBy;
    @track organizationSearchBy;

    get IndividualSearchByOptions() {
        return [
            { label: 'Email Address', value: 'EmailAddress' },
            { label: 'Phone Number', value: 'ContactNumber' },
            { label: 'Nationality & Passport Number', value: 'PassportNumber' },
            { label: 'Emirates ID', value: 'EmiratesId' }
        ];
    }

    handleOpenModal() {
        this.doGetNationality();
        this.doGetRegistrationAuthority();
        this.doGetMobileCountryCode();
        this.isShowModal = true;
    }

    handleCloseModal() {
        this.isShowModal = false;
    }

    handleIndividualChange(event) {
        this.accountResult = [];
        this.individualSearchBy = event.target.value;
        if (this.individualSearchBy === 'EmailAddress') {
            this.showByEmail = true;
            this.showByContact = false;
            this.showByPassport = false;
            this.showByEmiratesId = false;
        } else if (this.individualSearchBy === 'ContactNumber') {
            this.showByEmail = false;
            this.showByContact = true;
            this.showByPassport = false;
            this.showByEmiratesId = false;
        } else if (this.individualSearchBy === 'PassportNumber') {
            this.showByEmail = false;
            this.showByContact = false;
            this.showByPassport = true;
            this.showByEmiratesId = false;
        } else if (this.individualSearchBy === 'EmiratesId') {
            this.showByEmail = false;
            this.showByContact = false;
            this.showByPassport = false;
            this.showByEmiratesId = true;
        }
    }

    handleEmailChange(event) {
        this.emailAddress = event.target.value;
    }

    handleMobileCountryChange(event) {
        this.countryCode = event.target.value;
    }

    handleMobileChange(event) {
        this.ContactNo = event.target.value;
    }

    handleEIDChange(event) {
        this.EmiratesId = event.target.value;
    }

    handleNationalityChange(event) {
        this.nationality = event.target.value;
    }

    handlePassportChange(event) {
        this.passportNumber = event.target.value;
    }

    handleRegistrationAuthorityChange(event) {
        this.authority = event.target.value;
    }

    handleTradeLicenseChange(event) {
        this.licenseNo = event.target.value;
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

    doGetRegistrationAuthority() {
        this.showLoading = true;
        getRegistrationAuthority({}).then(result => {
            this.showLoading = false;
            if (result) {
                var registrationAuthorityOptions = [];
                for (var key in result) {
                    registrationAuthorityOptions.push({ value: key, label: result[key] });
                }
                this.registrationAuthorityList = registrationAuthorityOptions;
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

    handleAccountSearch() {
        if (this.showIndividualTab) {
            this.doGetIndividualAccount();
        } else if (this.showOrganisationTab) {
            this.doGetOrganizationAccount();
        }
    }

    doGetIndividualAccount() {
        this.showLoading = true;
        getIndividualAccount({ email: this.emailAddress, countryCode: this.countryCode, phoneNumber: this.mobileNumber, eid: this.emiratesId, passportNumber: this.passportNumber, nationality: this.nationality })
            .then(result => {
                if (result.length > 0) {
                    this.accountResult = result;
                } else {
                    this.accountResult = [];
                }
                this.showLoading = false;
            }).catch(error => {
                this.showLoading = false;
                var message;
                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    message = error.body.message;
                }
                this.showErrorMessage(JSON.stringify(message));
            })
    }

    doGetOrganizationAccount() {
        this.showLoading = true;
        getOrganizationAccount({ registrationAuthority: this.authority, tradeLicenseNumber: this.licenseNo })
            .then(result => {
                if (result.length > 0) {
                    this.accountResult = result;
                } else {
                    this.accountResult = [];
                }
                this.showLoading = false;
            }).catch(error => {
                this.showLoading = false;
                var message;
                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    message = error.body.message;
                }
                this.showErrorMessage(JSON.stringify(message));
            })
    }

    handleChangeTab(event) {
        this.accountResult = [];
        if (event.target.name == 'IndividualTab') {
            this.showIndividualTab = true;
            this.showOrganisationTab = false;

        } if (event.target.name == 'OrganizationTab') {
            this.showOrganisationTab = true;
            this.showIndividualTab = false;
        }
    }

    handleCreateLeadFromAccount(event) {
        let recordId = event.target.dataset.id;
        this.showLoading = true;
        createLeadFromAccount({ accountId: recordId })
            .then(result => {
                if (result) {
                    this.showSuccessMessage('Congratulations! Lead have been created successfully.');
                    this.navigateToLeadRecord(result);
                    this.showLoading = false;
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
            })
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