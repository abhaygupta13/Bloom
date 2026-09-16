import { LightningElement, api } from 'lwc';
import getPhoneDetails from '@salesforce/apex/CTIController.getPhoneDetails';
import createIntegrationRecord from '@salesforce/apex/CTIController.createIntegrationRecord';
import getSkillOptions from '@salesforce/apex/CTIController.getSkillOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ClickToDialAction extends LightningElement {

    phoneList = [];
    isLoading = false;
    styleElement;

    showSkillModal = false;
    selectedSkill = '';
    selectedPhoneNumber;
    selectedMaskedValue;

    skillOptions = [];

    disconnectedCallback() {
        if (this.styleElement) {
            document.body.removeChild(this.styleElement);
        }
    }

    @api
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadPhoneDetails();
        }
    }

    get recordId() {
        return this._recordId;
    }

    get isPhoneListEmpty() {
        return !this.isLoading && (!this.phoneList || this.phoneList.length === 0);
    }

    get showPhoneList() {
        return !this.isLoading && this.phoneList && this.phoneList.length > 0;
    }

    loadPhoneDetails() {
        
        this.isLoading = true;

        getPhoneDetails({recordId: this.recordId})
        .then(result => {
           this.phoneList = Object.keys(result).map(label => ({
                label: label,
                value: result[label]
            }));

            this.loadSkillOptions();
        })
        .catch(() => {
            this.showToast(
                'Error',
                'Failed to load phone numbers',
                'error'
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    loadSkillOptions() {
        getSkillOptions()
            .then(result => {
            this.skillOptions = result.map(skill => {
                const data = skill.trim();
                return { label: data, value: data };
            });
        })
        .catch(() => {
            this.showToast('Error', 'Failed to load Skill options.', 'error');
        });
    }

    // Opens Skill popup
    handleCall(event) {

        if (!this.skillOptions || this.skillOptions.length === 0) {
            this.showToast('Error', 'Skill options are not available.', 'error');
            return;
        }

        this.selectedLabel = event.currentTarget.dataset.label;
        if (this.skillOptions.length === 1) {
            this.showSkillModal = false;
            this.selectedSkill = this.skillOptions[0].value;
            this.handleSubmitSkill();
        } else {
            this.selectedSkill = '';
            this.showSkillModal = true;
        }
    }

    handleSkillChange(event) {
        this.selectedSkill = event.detail.value;
    }

    handleCancelSkill() {
        this.showSkillModal = false;
        this.selectedSkill = '';
    }

    handleSubmitSkill() {
        if (!this.selectedSkill) {
            this.showToast(
                'Error',
                'Please select a Skill.',
                'error'
            );
            return;
        }

        this.isLoading = true;

        createIntegrationRecord({
             recordId: this.recordId,
            label: this.selectedLabel,
            skill: this.selectedSkill
        })
        .then(() => {

            this.showSkillModal = false;
            this.showToast( 'Success', 'Call initiated successfully', 'success' );
            
            this.handleClose();
        })
        .catch(() => {
            this.showToast( 'Error', 'Failed to initiate call', 'error' );
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    handleClose(){
        // this.dispatchEvent(
        //     new CloseActionScreenEvent()
        // );
        this.dispatchEvent(
            new CustomEvent('close')
        );
    }
}