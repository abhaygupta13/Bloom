import { LightningElement, api, wire } from 'lwc';
import getCaseDetails from '@salesforce/apex/BCAPP_CaseController.getCaseDetails';
import updateCaseOwner from '@salesforce/apex/BCAPP_CaseController.updateCaseOwner';
import updateCaseStatus from '@salesforce/apex/BCAPP_CaseController.updateCaseStatus';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CaseActions extends LightningElement {
@api recordId; // Case ID
showAssignToMe = false;
showApprove = true;
showActions;
status;
isShowModal;
heading='';
isLoading;
handleRFI(event){
    this.status='Returned To Customer';
            this.comments='';
this.isShowModal=true;
    this.heading='Returned To Customer';


}

    handleReject(event){
    this.status='Rejected';
    this.comments='';
    this.isShowModal=true;
    this.heading='Reject Request';

}


handleApprove(event){
    this.status='Approved';
            this.comments='';
            this.isShowModal=true;
    this.heading='Approve Request';


}

hideModalBox() {  
    this.isShowModal = false;
}




// Fetch case details
@wire(getCaseDetails, { caseId: '$recordId' })
wiredCase({ error, data }) {
    if (data) {
        const caseStatus = data.caseStatus;
        const isAssignedToQueue = data.isAssignedToQueue;
        const isCurrentUserQueueMember = data.isCurrentUserQueueMember;
        console.log('isAssignedToQueue'+isAssignedToQueue);

            const caseOwnerId = data.caseOwnerId;
        const currentUserId = data.currentUserId;

        // Check if current user is the owner of the case
        this.isOwner = caseOwnerId === currentUserId;



        // Show "Assign to Me" button if assigned to a queue and user is a member
        if(caseStatus=='Submitted' || caseStatus=='Submitted to Community Management'){
        this.showAssignToMe = isAssignedToQueue && isCurrentUserQueueMember;

if(caseOwnerId != currentUserId){
this.showAssignToMe = true;
}
        }

        // Hide "Approve" button if status is "Approved"
        if(this.isOwner && (caseStatus=='Submitted' || caseStatus=='Submitted to Community Management'))
        this.showActions =true;
    } else if (error) {
        this.showToast('Error', 'Failed to fetch case details', 'error');
    }
}



showToast(title, message, variant) {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
    });
    this.dispatchEvent(event);
}
    handleCommentsChange(event) {
    this.comments = event.target.value;
}

handleActions() {

    if(!this.comments){

                this.showToast('Error', 'Case comments is mandatory', 'error');
return;
    }
    else{

    this.isLoading = true;
    updateCaseStatus({ caseId: this.recordId,status:this.status,comments:this.comments })
        .then((result) => {
console.log('wwwwww'+result);
if(result){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: result,
                    variant: 'error'
                })
            );
return;
}else{
            // Show success message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Case status updated to '+this.status,
                    variant: 'success'
                })
            );



        setTimeout(() => {
            location.reload();
        }, 2000);
}
        })
        .catch(error => {
            // Show error message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to update case status',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
}

    handleAssignToMe() {
    this.isLoading = true;
    updateCaseOwner({ caseId: this.recordId })
        .then(() => {
            // Show success message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Case owner updated successfully',
                    variant: 'success'
                })
            );


        setTimeout(() => {
            location.reload();
        }, 2000);

        })
        .catch(error => {
            // Show error message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to update case owner',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
}
}