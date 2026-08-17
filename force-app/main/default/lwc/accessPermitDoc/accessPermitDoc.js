import { LightningElement ,api,wire,track} from 'lwc';
import getDocument from '@salesforce/apex/SearchControllerFmApp.getDocument';
import { NavigationMixin } from 'lightning/navigation';
export default class AccessPermitDoc extends LightningElement {
   @api recordId='500FW000005zMs2YAE'; // Record ID passed from the parent component
   documentUrl = [];
   error;
   documents =[];
   @track logInpage=false;

    @wire(getDocument, { recordId: '$recordId' })
    wiredDocuments({ error, data }) {
        if (data) {
            // Append the correct Salesforce file preview URL for each document
            this.documents = data.map(doc => ({
                ...doc,
                fileUrl: `/lightning/r/ContentDocument/${doc.Id}/view` // Standard Salesforce file preview URL
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.documents = [];
            this.showToast('Error', 'Failed to fetch documents', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
    handleBack() {
        // Toggle visibility between components
        this.logInpage = true; // Show the search component when back button is clicked
    }
}