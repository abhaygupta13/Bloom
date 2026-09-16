import { LightningElement, api, wire} from 'lwc';
import getUnitDetails from '@salesforce/apex/CommunitySiteController.getUnitNVehicleParkingsByUnitIds';
import createVehicleDetails from '@salesforce/apex/CommunitySiteController.createVehicleDetails';
import getUnitsForCustomer from '@salesforce/apex/CommunitySiteController.getUnitsForCustomer';
import hasActiveVehicleRequest from '@salesforce/apex/CommunitySiteController.hasActiveVehicleRequest';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const ACCEPTED_FILE_FORMATS = ['.pdf','.jpeg'];

export default class VehicleParkingRegistration extends LightningElement {
    unitName;
    customerName;
    buildingName;
    numberOfCarParks;
    vehicleRows = [];
    draftValues = [];
    unitOptions = [];
    @api recordId;
    unitFound = false;
    error;
    unitId;
    vehicleParkingRecId;
    customerId;
    selectedUnitId;
    showSuccess = false;
    showLoading = false;
    projectId;
    projectName;
    isTenant = false;
    isOwner = false;
    tawtheeqStartDate;
    tawtheeqEndDate;
    uploadedFile;
    fileName = '';
    tenantFileName = 'Upload Tawtheeq / Ejari Document';
    ownerFileName = 'Upload Title Deed Document';
    dateError = false;
    showInProgressMessage = false;
    

    get label(){
        return this.isTenant ? this.tenantFileName : this.ownerFileName;
    }
    get isSaveDisabled() {
        // if(!this.fileName){
        //     return true;
        // }
        // return this.isTenant ? !(this.tawtheeqStartDate && this.tawtheeqEndDate && !this.dateError) : false;

        const allVehiclesFilled = this.vehicleRows.every(v => v.VehicleMakeModel && v.VehiclePlateNumber);
        const hasFile = this.fileName !== '';
        const tenantDateValid = !this.isTenant || (this.tawtheeqStartDate && this.tawtheeqEndDate && !this.dateError);
        console.log('allvehiclefilled---->>>'+allVehiclesFilled);
        console.log('hasFile---->>>'+hasFile);
        console.log('tenantDateValid---->>>'+tenantDateValid);
        return !(allVehiclesFilled && hasFile && tenantDateValid);
    }

    get acceptedFormats() {
        return ACCEPTED_FILE_FORMATS;
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.customerId = this.recordId != null ? this.recordId : currentPageReference.state?.id;
            console.log('---------------=======-------');
            console.log('Customer Id--->>>', this.customerId);
            console.log('recordId--->>>', this.recordId);
            console.log('Customer Id from URL--->>>>:', currentPageReference.state?.id);
            this.fetchUnits();
        }
    }

    // Fetch units for customer
    fetchUnits() {
        getUnitsForCustomer({ customerId: this.customerId })
            .then(data => {
                this.unitOptions = data.map(unitAllocation => ({
                    label: unitAllocation.Unit__r.Name,
                    value: unitAllocation.Unit__c
                }));

                if (data.length > 0) {
                    this.customerName = data[0].Account__r.Name;
                }

                if (this.unitOptions.length === 1) {
                    this.selectedUnitId = this.unitOptions[0].value;
                    this.handleUnitChange({ detail: { value: this.selectedUnitId } });
                }
            })
            .catch(error => {
                console.error('Error fetching units:', error);
                this.error = 'Failed to load units.';
            });
    }

    // Handle unit selection from picklist
    handleUnitChange(event) {
        this.showSuccess = false;
        this.resetUnitDetails();
        this.selectedUnitId = event.detail.value;
        if (!this.selectedUnitId) {
            return;
        }

        hasActiveVehicleRequest({accountId: this.customerId,unitId: this.selectedUnitId})
        .then(result => {
            if(result){
                this.unitFound = false;
                this.showInProgressMessage = true;
            } else {
                this.showInProgressMessage = false;
                this.loadUnitDetails(this.selectedUnitId);
            }
        })
    }
    resetUnitDetails(){
        this.tawtheeqStartDate = null;
        this.tawtheeqEndDate = null;
        this.fileName = '';
        this.vehicleRows = [];
    }

    handleFileUpload(event) {
        const file = event.target.files?.[0];
        if(!file){ 
            return;
        }
        this.fileName = file.name;
        const reader = new FileReader();
        reader.onload = () => {
                this.uploadedFile = {
                    filename: file.name,
                    base64: reader.result.split(',')[1],
                    type: file.type
                };
            }
            reader.readAsDataURL(file);
    }
    

    handleRemoveFile() {
        this.uploadedFile = null;
        this.fileName = '';
    }

    // Load unit detail and vehicle parking data
    loadUnitDetails(unitId) {
        getUnitDetails({ unitId })
            .then(unit => {
                this.isTenant = unit.ActiveTenant__c == this.customerId;
                this.isOwner = unit.Active_Sales_Order__r?.Account__c == this.customerId || false;
                this.unitName = unit.Name;
                this.unitId = unit.Id;
                this.projectId = unit.Project__c;
                this.projectName = unit.Project__r.Name;
                this.buildingName = unit.BuildingSectionName__r?.Name || '';
                this.vehicleRows = Array.from({ length: unit.NumberOfCarParks__c || 0 },(_, index) => ({
                        id: index + 1,
                    })
                );
                this.unitFound = true;
            })
            .catch(error => {
                console.error('Error loading unit details:', error);          
                this.unitFound = false;
            });
    }

    handleInputChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        // this.vehicleRows[index][field] = event.target.value;
        const updatedRows = [...this.vehicleRows];
        updatedRows[index] = { ...updatedRows[index], [field]: event.target.value };
        this.vehicleRows = updatedRows; 
    }

    handleTawtheeqDateChange(event) {
        if (event.target.name === 'tawtheeqStartDate') {
            this.tawtheeqStartDate = event.target.value;
        }
        if (event.target.name === 'tawtheeqEndDate') {
            this.tawtheeqEndDate = event.target.value;
        }

        if(this.tawtheeqStartDate && this.tawtheeqEndDate){
            if(new Date(this.tawtheeqStartDate) >= new Date(this.tawtheeqEndDate)){
                this.dateError = true;
            }
            else{
                this.dateError = false;
            }
        }
    }

    handleSave() {
        this.showLoading = true;
        const payload = [];
        for (const row of this.vehicleRows) {
            const hasData = row.VehicleMakeModel?.trim() || row.VehiclePlateNumber?.trim();
            if (hasData) {
                payload.push({
                    Unit__c: this.selectedUnitId,
                    VehicleMakeModel__c: row.VehicleMakeModel,
                    VehiclePlateNumber__c: row.VehiclePlateNumber
                });
            }
        }

        if (payload.length > 0) {
            const allDetails = {
                vehicles: payload,
                accId: this.customerId,
                accName: this.customerName,
                projectId: this.projectId,
                unitNumber: this.unitName,
                unitId: this.selectedUnitId,
                isTenant: this.isTenant,
                isOwner: this.isOwner,
                tawtheeqStartDate: this.tawtheeqStartDate,
                tawtheeqEndDate: this.tawtheeqEndDate,
                files: this.uploadedFile
            };
             createVehicleDetails({ allDetails: JSON.stringify(allDetails) })
                .then(() => {
                    this.showLoading = false;
                    this.showSuccessMessage('Vehicle parking records saved successfully!');
                    this.showSuccess = true;
                    this.unitFound = false;
                    this.selectedUnitId = null;
                    this.resetUnitDetails();
                })
                .catch(error => {
                    this.showLoading = false;
                    let message = error?.body?.message || error?.body?.pageErrors?.[0]?.message || 'An unknown error occurred';
                    this.showErrorMessage(message);
                });
        } else {
            this.showLoading = false;
            console.log('No changes to save.');
        }
    }

    handleCancel() {
        this.unitFound = false;
        this.selectedUnitId = null;
    }

    showErrorMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    showSuccessMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: msg,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}