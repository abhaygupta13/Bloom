import { LightningElement, api } from 'lwc';
import getSurveyLink from '@salesforce/apex/SurveyController.getSurveyLink';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RedirectToHandoverSurvey extends LightningElement {
    @api recordId;

    @api async invoke() {
        console.log('invoke called');
        console.log('recordId = ' + this.recordId);

        try {
            const url = await getSurveyLink({
                recordId: this.recordId
            });

            console.log('URL = ' + url);

            if (url) {
                window.open(url, '_blank');
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'No Survey Found',
                        message: 'No Survey record found linked to this Handover.',
                        variant: 'warning'
                    })
                );
            }
        } catch (e) {
            console.error(e);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Unable to fetch Survey URL',
                    variant: 'error'
                })
            );
        }
    }
}