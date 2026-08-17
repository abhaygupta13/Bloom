import { LightningElement, api, wire} from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getUnitDetails from '@salesforce/apex/CommunitySiteController.getUnitNVehicleParkingsByUnitIds';
import createVehicleDetails from '@salesforce/apex/CommunitySiteController.createVehicleDetails';
import getUnitsForCustomer from '@salesforce/apex/CommunitySiteController.getUnitsForCustomer';
import hasActiveVehicleRequest from '@salesforce/apex/CommunitySiteController.hasActiveVehicleRequest';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import VEHICLE_PARKING_DETAILS_OBJECT from '@salesforce/schema/VehicleParkingDetails__c';
import COUNTRY_REGION_FIELD from '@salesforce/schema/VehicleParkingDetails__c.CountryRegion__c';
import getCountryRegionValues from '@salesforce/apex/CommunitySiteController.getCountryRegionValues';
const ACCEPTED_FILE_FORMATS = ['.pdf','.jpeg'];


export default class VehicleParkingRegistration extends LightningElement {
    unitName;
    customerName;
    buildingName;
    numberOfCarParks;
    vehicleRows = [];
    draftValues = [];
    unitOptions = []; 
    countryOptions = [];
    recordTypeId;

    // countryOptions = [
    //     { label: 'AUH', value: 'AUH' }
    // ];
    // groupOptions = [
    //     { label: 'Block List', value: '0' },
    //     { label: 'Allow List', value: '1' }
    // ];

    @api recordId;

    @wire(getObjectInfo, { objectApiName: VEHICLE_PARKING_DETAILS_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;

            console.log(
                'Vehicle Parking Details Object:',
                data.apiName
            );

            console.log(
                'Default Record Type Id:',
                this.recordTypeId
            );
        } else if (error) {
            console.error('Object Info Error:', error);
        }
    }

   countryOptions = [];

@wire(getCountryRegionValues)
wiredCountryRegionValues({ data, error }) {

    console.log('===== COUNTRY REGION WIRE =====');

    if (data) {

        console.log(
            'Country Region Apex Data:',
            JSON.stringify(data)
        );

        this.countryOptions = data.map(value => ({
            label: value,
            value: value
        }));

        console.log(
            'Country Options:',
            JSON.stringify(this.countryOptions)
        );

        console.log(
            'Country Options Count:',
            this.countryOptions.length
        );

    } else if (error) {

        console.error(
            'Country Region Apex Error:',
            JSON.stringify(error)
        );

        this.countryOptions = [];
    }

    console.log('================================');
}
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

       // const allVehiclesFilled = this.vehicleRows.every(v => v.VehicleMakeModel && v.VehiclePlateNumber);
        const allVehiclesFilled = this.vehicleRows.every(v => v.VehicleMakeModel && v.VehiclePlateNumber && v.CountryRegion &&  v.Category !== null && v.Category !== undefined && v.Category !== '' && v.EffectiveStartDate && v.EffectiveEndDate );
        // Validate Start Date must be earlier than End Date
        const allVehicleDatesValid = this.vehicleRows.every(row => {
            if (!row.EffectiveStartDate || !row.EffectiveEndDate) {
                return false;
            }

            return new Date(row.EffectiveStartDate) < new Date(row.EffectiveEndDate);
        });
        const hasFile = this.fileName !== '';
        const tenantDateValid = !this.isTenant || (this.tawtheeqStartDate && this.tawtheeqEndDate && !this.dateError);
        console.log('allvehiclefilled---->>>'+allVehiclesFilled);
        console.log('hasFile---->>>'+hasFile);
        console.log('tenantDateValid---->>>'+tenantDateValid);
        //return !(allVehiclesFilled && hasFile && tenantDateValid);
        return !(allVehiclesFilled && allVehicleDatesValid && hasFile && tenantDateValid);
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
              //  this.vehicleRows = Array.from({ length: unit.NumberOfCarParks__c || 0 },(_, index) => ({
                      /// id: index + 1,
                   // })
                this.vehicleRows = Array.from({ length: unit.NumberOfCarParks__c || 0 }, (_, index) => ({
                    id: index + 1,
                    VehicleMakeModel: '',
                    VehiclePlateNumber: '',
                    CountryRegion: '',
                    Category:'',
                    EffectiveStartDate: '',
                    EffectiveEndDate: ''
                })
            
                );
                this.unitFound = true;
            })
            .catch(error => {
                console.error('Error loading unit details:', error);          
                this.unitFound = false;
            });
    }

   /* handleInputChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        // this.vehicleRows[index][field] = event.target.value;
        const updatedRows = [...this.vehicleRows];
        updatedRows[index] = { ...updatedRows[index], [field]: event.target.value };
        this.vehicleRows = updatedRows; 
    }*/

    handleCountryClick(event) {
    console.log('================================');
    console.log('COUNTRY REGION CLICKED');
    console.log('================================');

    console.log('Index:', event.target.dataset.index);
    console.log('Current value:', event.target.value);
    console.log('Country options:', JSON.stringify(this.countryOptions));
    console.log('Options count:', this.countryOptions.length);
   }

    handleInputChange(event) {
            const index = event.target.dataset.index;
            const field = event.target.name;

        console.log('========== HANDLE INPUT CHANGE ==========');
        console.log('Field:', field);
        console.log('Index:', index);
        console.log('Event target value:', event.target.value);
        console.log('Event detail:', JSON.stringify(event.detail));

            // const value = event.detail?.value ?? event.target.value;
            let value = event.detail?.value ?? event.target.value;
               // Specifically debug Country/Region
                if (field === 'CountryRegion') {
                    console.log('***** COUNTRY REGION DEBUG *****');
                    console.log('Selected Country/Region:', value);
                    console.log('Country/Region Index:', index);
                    console.log(
                        'Country Options:',
                        JSON.stringify(this.countryOptions)
                    );
                }
            // if (field === 'Category') {
            //     value = value === '' ? null : Number(value);
            // }
            if (field === 'VehiclePlateNumber') {
                value = value.replace(/\D/g, '').slice(0, 18);;
                event.target.value = value;
            }
            if (field === 'Category') {
                value = value.replace(/\D/g, '').slice(0, 2);
                event.target.value = value;
            }
            const updatedRows = [...this.vehicleRows];

            updatedRows[index] = {
                ...updatedRows[index],
                [field]: value
            };

             // Validate only when End Date is entered
             // Validate Start Date and End Date
            if ( field === 'EffectiveStartDate' || field === 'EffectiveEndDate') {
                const startDate = updatedRows[index].EffectiveStartDate;
                const endDate = updatedRows[index].EffectiveEndDate;

                if (startDate && endDate && new Date(startDate) >= new Date(endDate)) {
                    let message= 'Start Date must be earlier than End Date.';
                    //this.showErrorMessage(message);
                    event.target.setCustomValidity(
                        'Start Date must be earlier than End Date.'
                    );
                } else {
                    event.target.setCustomValidity('');
                }

                event.target.reportValidity();
            }
        

            this.vehicleRows = updatedRows;

            console.log('Field:', field);
            console.log('Value:', value);
            console.log('Updated Row:', JSON.stringify(updatedRows[index]));
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
               /* payload.push({
                    Unit__c: this.selectedUnitId,
                    VehicleMakeModel__c: row.VehicleMakeModel,
                    VehiclePlateNumber__c: row.VehiclePlateNumber
                });*/
                 payload.push({
                    Unit__c: this.selectedUnitId,
                    VehicleMakeModel__c: row.VehicleMakeModel,
                    VehiclePlateNumber__c: row.VehiclePlateNumber,
                    CountryRegion__c: row.CountryRegion,
                    Category__c: row.Category,
                    EffectiveStartDate__c: row.EffectiveStartDate,
                    EffectiveEndDate__c: row.EffectiveEndDate
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