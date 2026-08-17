import { LightningElement,api,wire} from 'lwc';
import searchLookupData from '@salesforce/apex/CustomLookup.searchLookupData';
import searchDefaultRecord from '@salesforce/apex/CustomLookup.searchDefaultRecord';
 
export default class CustomLookup extends LightningElement {
    // public properties with initial default values 
    @api label = 'label';
    @api placeholder = 'search...'; 
    @api iconName = 'standard:contact';
    @api sObjectApiName = 'Contact';
    @api defaultRecordId = '';
    // private properties 
    lstResult = []; // to store list of returned records   
    hasRecords = true; 
    searchKey=''; // to store input field value    
    isSearchLoading = false; // to control loading spinner  
    delayTimeout;
    isValueSelected;
    selectedRecord = {}; // to store selected lookup record in object formate 
    @api filterValue = '';

   // initial function to populate default selected lookup record if defaultRecordId provided  
    connectedCallback(){
         if(this.defaultRecordId != ''){
            searchDefaultRecord({ recordId: this.defaultRecordId , 'sObjectApiName' : this.sObjectApiName })
            .then((result) => {
                if(result != null){
                    this.selectedRecord = result;
                    this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
                }
            })
            .catch((error) => {
                this.error = error;
                this.selectedRecord = {};
            });
         }
    }
    // wire function property to fetch search record based on user input
    @wire(searchLookupData, { searchKey: '$searchKey' , sObjectApiName : '$sObjectApiName',parentId: '$filterValue' })
     searchResult(value) {
        const { data, error } = value; // destructure the provisioned value
        this.isSearchLoading = false;
        if (data) {
             this.hasRecords = data.length == 0 ? false : true; 
             this.lstResult = JSON.parse(JSON.stringify(data)); 
         }
        else if (error) {
            console.log('(error---> ' + JSON.stringify(error));
         }
    };
        
  // update searchKey property on input field change  
    handleKeyChange(event) {
        // Do not update the reactive property as long as this function is
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
        this.searchKey = searchKey;
        }, 300);
    }
    // method to toggle lookup result section on UI 
    toggleResult(event){
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch(whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
               break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');    
            break;                    
           }
    }
    // method to clear selected lookup record  
    @api handleRemove(){
        this.searchKey = '';    
        this.selectedRecord = {};
        this.lookupUpdateParenthandler(undefined); // update value on parent component as well from helper function
        this.isValueSelected = false; 
    }
    // update selected record from search result 
    handelSelectedRecord(event){   
        var objId = event.target.getAttribute('data-recid'); // get selected record Id 
        this.selectedRecord = this.lstResult.find(data => data.Id === objId); // find selected record from list 
        this.lookupUpdateParenthandler(this.selectedRecord); // update value on parent component
        this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
    }
    //handle select record
    handelSelectRecordHelper(){
        this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');
        this.isValueSelected = true; 
    }
    // send selected lookup record to parent component using custom event
    lookupUpdateParenthandler(value){
        console.log(value);
        const oEvent = new CustomEvent('lookupupdate',
                                    {
                                        'detail': {selectedRecord: value}
                                    }
                        );
        this.dispatchEvent(oEvent);
    }
}