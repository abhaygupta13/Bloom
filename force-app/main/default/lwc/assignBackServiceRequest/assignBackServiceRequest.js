import { LightningElement, api, track, wire } from 'lwc';
import getAssignBackReasons from '@salesforce/apex/AssignBackServiceRequestController.getAssignBackReasons';
import handleAssignBack from '@salesforce/apex/AssignBackServiceRequestController.handleAssignBack';
import getTeamUsers from '@salesforce/apex/AssignBackServiceRequestController.getTeamUsers';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { RefreshEvent } from 'lightning/refresh';

export default class AssignBackServiceRequest extends NavigationMixin(LightningElement) {
    
    @track selectedReason = '';
    @track description = '';
    @track showPicklistError = false;
    @track reasonOptions = [];
    @track isLoading = false;
   @track isEscalation = false;
    @track userOptions = [];
    @track selectedUserId;
@track teamOptions = [];
@track selectedTeam;
@track allUsersByTeam = {};
    _recordId;

    @api
    set recordId(value) {
        this._recordId = value;

        if (value) {
            this.fetchUsers();
        }
    }

    get recordId() {
        return this._recordId;
    }

    @wire(getAssignBackReasons)
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.reasonOptions = data.map(value => ({ label: value, value: value }));
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }

   
  fetchUsers() {
    getTeamUsers({ caseId: this.recordId })
        .then(result => {

            this.allUsersByTeam = result;

            // Build Team dropdown
            this.teamOptions = Object.keys(result).map(key => ({
                label: key,
                value: key
            }));

            this.userOptions = []; // reset users
        })
        .catch(error => {
            console.error('Error fetching users:', error);
        });
}
handleTeamChange(event) {
    this.selectedTeam = event.detail.value;

    const users = this.allUsersByTeam[this.selectedTeam] || [];

    this.userOptions = users.map(u => ({
        label: u.label,
        value: u.value
    }));
}
    handleUserChange(event) {
        this.selectedUserId = event.detail.value;
    }

    handlePicklistChange(event) {
        this.selectedReason = event.detail.value;
        this.showPicklistError = false;
    }

    handleDescriptionChange(event) {
        this.description = event.detail.value;
    }

    handleSubmit() {
    if (!this.selectedReason) {
        this.showPicklistError = true;
        return;
    }

 if (!this.selectedTeam) {
        this.showToast('Error', 'Please select a team', 'error');
        return;
    }

    if (!this.selectedUserId) {
        this.showToast('Error', 'Please select a user', 'error');
        return;
    }
    this.isLoading = true;

    handleAssignBack({ 
        caseId: this.recordId, 
        commentBody: this.description,
        reason: this.selectedReason,
        userId: this.selectedUserId,
        team: this.selectedTeam,
        isEscalation: this.isEscalation   
    })
    .then(() => {
        this.isLoading = false;

        this.showToast('Success', 'Service Request reassigned successfully!', 'success');
this.dispatchEvent(new CloseActionScreenEvent());

setTimeout(() => {
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: this.recordId,
            actionName: 'view'
        }
    });
}, 300);
       
    })
    .catch(error => {
        console.error('Error in Assign Back:', error);

        this.isLoading = false;
        this.showToast('Error', this.getErrorMessage(error), 'error');
    });
}

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    getErrorMessage(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        return 'An unexpected error occurred.';
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
    handleEscalationChange(event) {
    this.isEscalation = event.target.checked;
}
}