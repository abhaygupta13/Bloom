import { LightningElement, api, track } from 'lwc';
import getFiles from '@salesforce/apex/DownloadZip.getFiles';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DownloadZipQuickAction extends NavigationMixin(LightningElement) {
  
    @api recordId;
    @track fileIds = '';

    @api invoke() {
       
        getFiles({
            recordId: this.recordId
        })
        .then(result => { 
            let fileList = JSON.parse(JSON.stringify(result));
            if (fileList !== '') { 
                for (let i in fileList) { 
                    this.fileIds += fileList[i] + '/';
                }
            }
            
            if (this.fileIds.length > 0) { 
                this.fileIds = this.fileIds.replace(/.$/, "?");

                const config = {
                    type: 'standard__webPage',
                    attributes: {
                        url: '/sfc/servlet.shepherd/version/download/' + this.fileIds
                    }
                };
                this[NavigationMixin.Navigate](config);
            } else {
                // Handle the case where fileList is empty
                const evt = new ShowToastEvent({
                    title: 'Toast Error',
                    message: 'File Is not Available',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt); // Dispatch the toast event
            }
        })
        .catch(error => {
            console.log('### Error: ' + JSON.stringify(error));
            // Handle the error and show a toast message
            const evt = new ShowToastEvent({
                title: 'Toast Error',
                message: 'Some unexpected error',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt); // Dispatch the toast event
        });
    }
}