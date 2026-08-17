import { LightningElement, api, track,wire } from 'lwc';
import checkAndCreateAzureB2CUser from '@salesforce/apex/MicrosoftAzureB2CUtility.checkAndCreateAzureB2CUser';
import { CurrentPageReference } from 'lightning/navigation';

export default class AzureB2CUserLWC extends LightningElement {
    @track showPopup = false; 
    @track popupMessage = ''; 
    wireRecordId;
    currectRecordId;
     @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentPageReference ', currentPageReference);
            //it gets executed before the connected callback and avilable to use
            this.wireRecordId = currentPageReference.state.recordId;
        }
    }
    @api set recordId(value) {
        this.currectRecordId = value;
        console.log('this.currectRecordId ',this.currectRecordId);

        //onload action here where you need current recordid
        //this gets executed post connected callback
    }

    get recordId() {
        return this.currectRecordId;
    }


  

    connectedCallback() {
    
        debugger;
        checkAndCreateAzureB2CUser({ userId: this.wireRecordId })
            .then((result) => {
                this.popupMessage = result;
                this.showPopup = true;
            })
            .catch((error) => {
                this.popupMessage = 'Error: ' + error.body.message;
                this.showPopup = true;
            });
    }

    closePopup() {
        this.showPopup = false;
    }
}