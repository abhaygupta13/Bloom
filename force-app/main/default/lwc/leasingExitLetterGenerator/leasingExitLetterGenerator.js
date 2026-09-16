import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateDocument from '@salesforce/apex/LeasingDocGenController.generateDocument';
import getDocgenSetupRecords from '@salesforce/apex/LeasingDocGenController.getDocgenSetupRecords';

export default class LeasingExitLetterAction extends LightningElement {

    @api recordId;
    isLoading = false;

    async handleGenerate() {
        this.isLoading = true;

        try {
            const records = await getDocgenSetupRecords({
                recordId: this.recordId
            });
            console.log(JSON.stringify(records));
            const exitLetter = records.find(
                record => record.Type__c === 'Leasing Exit Letter'
            );

            if (!exitLetter) {
                throw new Error(
                    'Leasing Exit Letter Document Type is not configured.'
                );
            }

            if (!exitLetter.DeliveryOption__c || !exitLetter.DocGenPackage__c) {
                throw new Error(
                    'Delivery Option or DocGen Package is missing.'
                );
            }

            await generateDocument({
                deliveryOptionId: exitLetter.DeliveryOption__c,
                templateId: exitLetter.DocGenPackage__c,
                recordId: this.recordId,
                documentName: exitLetter.Type__c
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Leasing Exit Letter generated successfully.',
                    variant: 'success'
                })
            );

            // Close Quick Action
         this.dispatchEvent(new CustomEvent('closequickaction'));

        } catch (error) {

            console.error('Exit Letter generation error:', error);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message:
                        error?.body?.message ||
                        error?.message ||
                        'Unable to generate Exit Letter.',
                    variant: 'error'
                })
            );

        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
         this.dispatchEvent(new CustomEvent('closequickaction'));
    }
}