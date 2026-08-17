import { LightningElement, track, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import exportData from '@salesforce/apex/dataExportAsExcelHandler.exportData'
export default class DataExportAsExcelHelper extends LightningElement {
    @api recordId;
    @api identifier;
    @track isLoading;
    @track callOnce = true;



    connectedCallback() {

        if (this.callOnce) {
            exportData({ parentId: this.recordId, identifier: this.identifier })
                .then(result => {
                    this.callOnce = false;

                    if (result && result.length > 0) {
                        this.isLoading = true;

                        let columnHeaders = Object.keys(result[0]);
                        //Data preparation
                        let doc = '<table>';
                        doc += '<tr>';
                        columnHeaders.forEach(element => {
                            doc += '<th>' + element + '</th>'
                        });
                        doc += '</tr>';
                        // Add the data rows
                        result.forEach(item => {
                            doc += '<tr>';
                            columnHeaders.forEach(head => {
                                doc += '<th>' + item[head] + '</th>';

                            });
                            doc += '</tr>';
                        });
                        doc += '</table>';

                        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
                        let downloadElement = document.createElement('a');
                        downloadElement.href = element;
                        downloadElement.target = '_self';
                        // use .csv as extension on below line if you want to export data as csv
                        downloadElement.download = this.identifier + 'Data.xls'; //OrderData.csv
                        document.body.appendChild(downloadElement);
                        downloadElement.click();

                        this.isLoading = false;

                        
                        this.dispatchEvent(new CustomEvent('closeaction', {
                            detail: ''
                        }));
                    } else {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'error',
                                message: 'Records Are Not Available.',
                                variant: 'error'
                            })
                        );
                        this.dispatchEvent(new CustomEvent('closeaction', {
                            detail:''
                        }));
                    }



                }).catch(error => {
                    this.error = error;
                    this.dispatchEvent(new CloseActionScreenEvent());
                })

        }
    }



}