import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getContactUsVCardDownloadUrl from '@salesforce/apex/QRCodeController.getContactUsVCardDownloadUrl';

export default class SalesQRCode extends NavigationMixin(LightningElement) {

    handleUAEPassClick(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://smarthub.adm.gov.ae/login'
            }
        });
    }

    handleContactUsClick(event) {
        getContactUsVCardDownloadUrl().then(vCardUrl => {
            const a = document.createElement('a');
            a.href = vCardUrl;
            a.download = 'contact.vcf';
            a.style.display = 'none';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
        }).catch(error => {
            console.error('Error generating vCard:', error);
        });
    }
}