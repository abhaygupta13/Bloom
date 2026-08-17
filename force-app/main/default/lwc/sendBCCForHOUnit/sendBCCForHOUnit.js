import { LightningElement, track, wire } from 'lwc';
import { RefreshEvent } from 'lightning/refresh';
import getProjects from '@salesforce/apex/HandoverController.getProjects';
import getBuildings from '@salesforce/apex/HandoverController.getBuildings';
import getUnits from '@salesforce/apex/HandoverController.getUnits';
import getUnitToMakeReady from '@salesforce/apex/HandoverController.getUnitToMakeReady';
import sendBCCMailToCustomer from '@salesforce/apex/HandoverController.sendBCCEmails';
import sendOrientationMailToCustomer from '@salesforce/apex/HandoverController.sendOrientationEmails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendBCCLWCHeading1 from '@salesforce/label/c.sendBCCLWCHeading';
import noRecordFound from '@salesforce/label/c.noRecordFound';
import selectAtleastOneRecord from '@salesforce/label/c.selectAtleastOneRecord';
import bccEmailSent from '@salesforce/label/c.bccEmailSent';
import orientationEmailSent from '@salesforce/label/c.OrientationEmailSent';
import bccEmailError from '@salesforce/label/c.bccEmailError';
import unitButtonLabel from '@salesforce/label/c.unitButtonLabel';
import bccButtonL from '@salesforce/label/c.bccButtonLabel';
import sendNOCHeading from '@salesforce/label/c.sendNOCLWCHeading';
import nocButtonL from '@salesforce/label/c.nocButtonLabel';
import getNOCUnits from '@salesforce/apex/HandoverController.getNOCUnits';
import sendNOCMailToCustomer from '@salesforce/apex/HandoverController.sendNOCEmails';
import sendCHOHeading from '@salesforce/label/c.sendCHOInviteHeading';

const columns = [
    { label: 'Handover Name', fieldName: 'handoverName', sortable: "true" },
    { label: 'Unit Name', fieldName: 'unitName', sortable: "true" },
    { label: 'Unit Status', fieldName: 'unitStatus', sortable: "true" },
    { label: 'Active Sales Order', fieldName: 'activeSalesOrder', sortable: "true" },
    { label: 'Building Name', fieldName: 'buildingName', sortable: "true" },
    { label: 'Owner', fieldName: 'OwnerName', sortable: "true" },
    { label: 'Created Date', fieldName: 'createdDate', sortable: "true" }
];

export default class SendBCCForHOUnit extends LightningElement {
    label = {
        sendBCCLWCHeading1,
        noRecordFound,
        selectAtleastOneRecord,
        bccEmailSent,
        orientationEmailSent,
        bccEmailError,
        unitButtonLabel,
        bccButtonL,
        sendNOCHeading,
        nocButtonL,
        sendCHOHeading
    };

    @track flags = {
        isVisiableTable: false,
        isLoading: true,
        heading1: 'Select units to send BCC',//Custom label Send BCC LWC Heading
        projLabel: 'Choose Project',
        buildLabel: 'Choose Building',
        placeholder: 'Select Object',
        curntSelectedObjValue: '',
        projectObjOptions: [],
        buildingObjOptions: [],
        selectedProjectId: '',
        selectedBuildingId: '',
        tableData: [],
        tableColumns: columns,
        sendBCCMailtoCustomers: false,
        makeUnitReady: false,
        batchJobId: '',
        sendNOCMailtoCustomers: false,
    }
    selectedRecordCount = 0;
    sendBCCMailNotification=false;
    sendNOCMailNotification=false;
    sendCHONotification=false;

    @track sortBy;
    @track sortDirection;

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.flags.tableData));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.flags.tableData = parseData;
    }


    // load handover related project on component load
    // @wire(getProjects)
    // wiredSObjectNames({ error, data }) {
    //     if (data) {
    //         console.log('data - ' , data);
    //         this.flags.projectObjOptions = data;
    //         // load handover related units on component load
    //        // this.getUnitsofHandover();
    //     } else if (error) {
    //         //console.error('Error retrieving SObject names:', error);
    //         this._showToastMessage('Error', this.label.noRecordFound, 'error');
    //     }
    //     this.flags.isLoading = false;
    // }
    connectedCallback() {
        getProjects()
            .then(data => {
                console.log('data - ', data);
                this.flags.projectObjOptions = data;
                // load handover related units on component load
                // this.getUnitsofHandover();
                this.flags.isLoading = false;
            })
            .catch(error => {
                //console.error('Error retrieving SObject names:', error);
                this._showToastMessage('Error', this.label.noRecordFound, 'error');
                this.flags.isLoading = false;
            });
    }

    handleSObjectChange(event) {
        this.flags.isLoading = true;
        let comboxType = event.target.name;
        let selectedId = event.detail.value;
        if (comboxType === 'Choose_Project_Obj') {
            this.flags.selectedProjectId = '';
            this.flags.buildingObjOptions = [];
            this.flags.selectedBuildingId = '';
            this.flags.tableData = [];
            this.flags.isVisiableTable = false;
            this.flags.selectedProjectId = selectedId;

            // load handover related building after project selection 
            getBuildings({ projectId: selectedId })
                .then(res => {
                    if (res) {
                        this.flags.buildingObjOptions = res;
                    } else {
                        //this._showToastMessage('Error', this.label.noRecordFound, 'error');
                    }
                })
                .catch(err => {
                    this._showToastMessage('Error', err, 'error');
                })
        } else if (comboxType === 'Choose_Building_Object') {
            this.flags.selectedBuildingId = '';
            this.flags.tableData = [];
            this.flags.isVisiableTable = false;
            this.flags.selectedBuildingId = selectedId;
        }
        this.flags.isLoading = false;
    }

    onUnitReadyTabClick() {
         this.sendBCCMailNotification=false;
        this. sendNOCMailNotification=false;
        this. sendCHONotification=true;
        this.flags.curntSelectedObjValue = '';
        this.flags.selectedProjectId = '';
        this.flags.selectedBuildingId = '';
        this.flags.tableData = '';
        this.flags.makeUnitReady = true;
       // this.flags.sendBCCMailtoCustomers = false;
        this.getNonReadyUnits();
    }
    sendUnitToBCC() {
        
        this.flags.curntSelectedObjValue = '';
        this.flags.selectedProjectId = '';
        this.flags.selectedBuildingId = '';
        this.flags.tableData = '';
        this.sendBCCMailNotification=true;
        this. sendNOCMailNotification=false;
        this. sendCHONotification=false;
      //  this.flags.makeUnitReady = false;
      //  this.flags.sendBCCMailtoCustomers = true;
        this.getUnitsofHandover();
    }
    sendUnitToNOC() {
       
        this.flags.curntSelectedObjValue = '';
        this.flags.selectedProjectId = '';
        this.flags.selectedBuildingId = '';
        this.flags.tableData = '';
       // this.flags.makeUnitReady = false;
      //  this.flags.sendBCCMailtoCustomers = false;
        
       // this.flags.sendNOCMailtoCustomers = true;
        this.sendBCCMailNotification=false;
        this. sendNOCMailNotification=true;
        this. sendCHONotification=false;
        this.getUnitsofNOC();
    }
   


    

    handleSearchClick(event) {
        this.getUnitsofHandover();
    }

    handleNOCSearchClick(event) {
        this.getUnitsofNOC();
    }

    handleUnitReadySearch(event) {
        this.getNonReadyUnits();
    }

    getUnitsofHandover() {
        //  console.log('getUnitsofHandover');
        getUnits({ projectId: this.flags.selectedProjectId, buildingId: this.flags.selectedBuildingId })
            .then(res => {
                console.log('Table res: ', JSON.stringify(res));
                if (res.length > 0) {
                    this.flags.isVisiableTable = true;
                    this.flags.tableData = res;
                    this.flags.sendBCCMailtoCustomers = true;
                    console.log('Table res: ', JSON.stringify(this.flags.tableData));
                } else {
                    this.flags.sendBCCMailtoCustomers = false;

                    // this._showToastMessage('Error', this.label.noRecordFound, 'error');
                }
            })
            .catch(err => {
                this._showToastMessage('Error', err, 'error');//'No record found '+
            })
    }

    getUnitsofNOC() {
        //  console.log('getUnitsofHandover');
        getNOCUnits({ projectId: this.flags.selectedProjectId, buildingId: this.flags.selectedBuildingId })
            .then(res => {
                console.log('Table res: ', JSON.stringify(res));
                if (res.length > 0) {
                    this.flags.isVisiableTable = true;
                    this.flags.tableData = res;
                    this.flags.sendNOCMailtoCustomers = true;
                    console.log('Table res: ', JSON.stringify(this.flags.tableData));
                } else {
                    this.flags.sendNOCMailtoCustomers = false;

                    // this._showToastMessage('Error', this.label.noRecordFound, 'error');
                }
            })
            .catch(err => {
                this._showToastMessage('Error', err, 'error');//'No record found '+
            })
    }

    getNonReadyUnits() {
        console.log('getUnitToMakeReady');
        getUnitToMakeReady({ projectId: this.flags.selectedProjectId, buildingId: this.flags.selectedBuildingId })
            .then(res => {
                console.log('Table res: ', JSON.stringify(res));
                if (res.length > 0) {
                    this.flags.isVisiableTable = true;
                    this.flags.tableData = res;
                    this.flags.makeUnitReady = true;
                    console.log('Table res: ', JSON.stringify(this.flags.tableData));
                } else {
                    this.flags.makeUnitReady = false;

                    // this._showToastMessage('Error', this.label.noRecordFound, 'error');
                }
            })
            .catch(err => {
                this._showToastMessage('Error', err, 'error');//'No record found '+
            })
    }

    handleSubmit() {
        if (this.selectedRecordCount > 25) {
    this.flags.isLoading = false;
    this._showToastMessage('Error', 'You cannot select more than 25 units at a time.', 'error');
    return;
}

        if (this._isInputValid()) {
            this.flags.isLoading = true;
            let selectedIds = [];
            var customerEmailNotFound = '';
            var SOADocNotFound = '';
            let selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
            console.log("selected Rows: ", selectedRows);
            let errorMessages = [];

            if (selectedRows && selectedRows.length === 0) {
                this.flags.isLoading = false;
                this._showToastMessage('Error', this.label.selectAtleastOneRecord, 'error');
            } else {
                selectedRows.forEach((row) => {
                    if (row.handoverCustomerEmail === "") {
                        customerEmailNotFound = customerEmailNotFound + ', ' + row.handoverName;
                    } else if (row.contentDocId === "") {
                        SOADocNotFound = SOADocNotFound + ', ' + row.handoverName;
                    } else {
                        selectedIds.push(row.Id);
                    }
                });

                if (customerEmailNotFound.length > 0) {
                    this._showToastMessage('Error', 'Customer Email not found for these Handover: ' + customerEmailNotFound, 'error');
                }
                if (SOADocNotFound.length > 0) {
                    this._showToastMessage('Error', 'Please add SOA Document for these Handover: ' + SOADocNotFound, 'error');
                }

                if (selectedIds.length > 0) {
                    console.log("Selected IDs: ", selectedIds);
                    console.log('selectedIds - ', JSON.stringify(selectedIds));

                    sendBCCMailToCustomer({ recordIds: selectedIds })
                        .then(result => {
                            console.log('result: ', JSON.stringify(result));
                            if (result) {
                                console.log('under if result: ', JSON.stringify(result));
                                this.flags.isLoading = false;
                                this._showToastMessage('Success', result, 'success');
                                window.location.reload();


                            }
                        })
                        .catch(error => {
                            console.log('error: ', error);
                        });
                }
                else {
                    this.flags.isLoading = false;
                }
            }

            if (errorMessages.length > 0) {
                this._showToastMessage('Error', errorMessages.join('\n'), 'error');
            }
        }
    }

    handleNOCSubmit() {
        if (this.selectedRecordCount > 30) {
    this.flags.isLoading = false;
    this._showToastMessage('Error', 'You cannot select more than 30 units at a time.', 'error');
    return;
}

        if (this._isInputValid()) {
            this.flags.isLoading = true;
            let selectedIds = [];
            var customerEmailNotFound = '';
            var SOADocNotFound = '';
            var QASnagDocNotFound = '';
            let selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
            //var selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
            console.log("selected Rows: ", selectedRows);
            let errorMessages = [];
            console.log("selectedRows: ", selectedRows);
            if (selectedRows && selectedRows.length === 0) {
                this.flags.isLoading = false;
                this._showToastMessage('Error', this.label.selectAtleastOneRecord, 'error');
            } else {
                selectedRows.forEach((row) => {
                    if (row.handoverCustomerEmail === "") {
                        console.log('Email Not Found');
                        customerEmailNotFound = customerEmailNotFound + ', ' + row.handoverName;
                    } else if (row.SOADocId === "") {
                        console.log('SOADocNotFound Not Found');
                        SOADocNotFound = SOADocNotFound + ', ' + row.handoverName;
                    } else if (row.QASnagDocId === "") {
                        console.log('QASnagDocNotFound Not Found');
                        QASnagDocNotFound = QASnagDocNotFound + ', ' + row.handoverName;
                    } else {
                        selectedIds.push(row.Id);
                    }
                });

                if (customerEmailNotFound.length > 0) {
                    console.log('Email Not Found');
                    this.flags.isLoading = false;
                    this._showToastMessage('Error', 'Customer Email not found for these Handover: ' + customerEmailNotFound, 'error');
                }
                if (SOADocNotFound.length > 0) {
                    console.log('SOADocNotFound Not Found');
                    this.flags.isLoading = false;
                    this._showToastMessage('Error', 'Please add SOA Document for these Handover: ' + SOADocNotFound, 'error');
                }
                if (QASnagDocNotFound.length > 0) {
                    console.log('QASnagDocNotFound Not Found');
                    this.flags.isLoading = false;
                    this._showToastMessage('Error', 'Please add Desnagging Report Document for these Handover: ' + QASnagDocNotFound, 'error');
                }

                console.log("Selected NOC IDs: ", selectedIds);
                console.log('selectedIds NOC - ', JSON.stringify(selectedIds));
                if (selectedIds.length > 0) {
                    sendNOCMailToCustomer({ recordIds: selectedIds })
                        .then(result => {
                            if (result) {
                                console.log('undet if result: ', JSON.stringify(result));
                                this.flags.isLoading = false;
                                this._showToastMessage('Success', result, 'success');
                                window.location.reload();

                            }
                        })
                        .catch(error => {
                            console.log('error: ', error);
                        })
                } else {
                    this.flags.isLoading = false;
                }
            }
            if (errorMessages.length > 0) {
                this._showToastMessage('Error', errorMessages.join('\n'), 'error');
            }
            //}
        }
    }

    handleUnitReadySubmit() {
         if (this.selectedRecordCount > 25) {
    this.flags.isLoading = false;
    this._showToastMessage('Error', 'You cannot select more than 25 units at a time.', 'error');
    return;
}
     
        if (this._isInputValid()) {
            this.flags.isLoading = true;
            let selectedIds = [];
            let selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
            //var selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
            console.log("selected Rows: ", selectedRows);
            var errorMessages = '';
            //if(selectedRows!=null){
            if (selectedRows && selectedRows.length === 0) {
                this.flags.isLoading = false;
                this._showToastMessage('Error', this.label.selectAtleastOneRecord, 'error');
            }
            //if(selectedRows.length == 0){
            //this.flags.isLoading = false;
            // this._showToastMessage('Error', this.label.selectAtleastOneRecord, 'error');
            //}
            else {
                selectedRows.forEach((row) => {
                    if (row.SPADocId === "") {
                        errorMessages = errorMessages + ', ' + row.handoverName;
                    } else {
                        selectedIds.push(row.Id);
                    }
                });
                if (errorMessages.length > 0) {
                    this._showToastMessage('Error', 'Please add SPA on these Handover: ' + errorMessages, 'error');
                }
                console.log("Selected IDs: ", selectedIds);
                console.log('selectedIds - ', JSON.stringify(selectedIds));
                if (selectedIds.length > 0) {
                    
                    sendOrientationMailToCustomer({ recordIds: selectedIds })
                        .then(result => {
                            if (result) {
                                console.log('undet if result: ', JSON.stringify(result));
                                this.flags.isLoading = false;
                                this._showToastMessage('Success', result, 'success');
                                window.location.reload();

                            }
                        })
                        .catch(error => {
                            console.log('error: ', error);
                        })
                } else {
                    this.flags.isLoading = false;
                }
            }
            //}
        }
    }
    checkBatchStatus(message) {
        isBatchCompleted({ batchJobId: this.flags.batchJobId })
            .then(result => {
                if (result) {
                    console.log('result result result', result);
                    this.flags.isLoading = false;
                    this._showToastMessage('Success', message, 'success');
                    window.location.reload();
                } else {

                }
            })
            .catch(error => {
                console.log('batch error--->' + error);
            });
    }

    //convert Array In oombobox Options 
    _changeArrayFormat(dataArr) {
        let tempArr = [];
        if (dataArr.length > 0) {
            dataArr.forEach(currentItem => {
                tempArr.push({ label: currentItem.Name, value: currentItem.Id });
            });
        }
        return tempArr;
    }

    // check input field has value or not
    _isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if (!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    previousValidSelection = [];

    previousValidSelectionIds = [];

handleRowSelection(event) {
    const selectedRows = event.detail.selectedRows;
    const selectedIds = selectedRows.map(r => r.Id);

    // If user selected more than 15
    if (selectedIds.length > 25) {
        this._showToastMessage('Error', 'You cannot select more than 25 units at a time.', 'error');

        // Restore selection by IDs
        this.template.querySelector('lightning-datatable').selectedRows =
            this.previousValidSelectionIds;

        return;
    }

    // Store valid selection
    this.previousValidSelectionIds = selectedIds;
    this.selectedRecordCount = selectedIds.length;
}


    _showToastMessage(title, message, type) {
        const toastEvt = new ShowToastEvent({
            title: title,
            message: message,
            variant: type,
            mode: 'sticky'
        });
        this.dispatchEvent(toastEvt);
    };


}