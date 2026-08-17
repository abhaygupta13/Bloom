import { LightningElement, track ,api} from 'lwc';
import searchRecords from '@salesforce/apex/SearchControllerFmApp.searchRecords';
import BLOOM_LOGO from '@salesforce/resourceUrl/BloomLogo';




export default class SearchScreen extends LightningElement {
    @api loginuserId='ed0bc7a7-5b0f-4048-8861-a66adf18baf9'; 
    @track searchTerm = '';
    @track results = [];
    @track isLoading = false;
    @track selectedContactId = null;
    @track selectedValue = 'checkin';
    @track authHeader;
    @track ischeckout = false;
    @track noResults = false;
    bloomLogoUrl = BLOOM_LOGO;
    noResults
    connectedCallback() {
        this.fetchAuthHeader();
    }

    columns = [
    { label: 'Permit Number', fieldName: 'Request_Number__c', type: 'text',hideDefaultActions: true, initialWidth: 150 ,wrapText: false},
    { label: 'Unit', fieldName: 'Unit_Name_Formula__c', type: 'text',hideDefaultActions: true,wrapText: false,initialWidth: 150  },
    { label: 'Status', fieldName: 'Status', type: 'text' ,hideDefaultActions: true,wrapText: false,initialWidth: 150 },
    {   label: 'Action',
        type: 'button',
        initialWidth: 150,
        wrapText: false,
        typeAttributes: {
            label: 'Edit',
            name: 'edit',
            variant: 'brand',
            hideDefaultActions: true
        }
    }
];
  checkoutcolumns = [
    { label: 'Permit Number', fieldName: 'ParentRequestNumber__c', type: 'text' ,hideDefaultActions: true, initialWidth: 150,wrapText: false},
    { label: 'Unit', fieldName: 'Unit_Name_Formula__c', type: 'text',hideDefaultActions: true,initialWidth: 150,wrapText: false },
    { label: 'Status', fieldName: 'Status', type: 'text',hideDefaultActions: true,initialWidth: 150,wrapText: false },
    {
        type: 'button',
        initialWidth: 150,
        wrapText: false,
        label: 'Action',
        typeAttributes: {
            label: 'Edit',
            name: 'edit',
            variant: 'brand',
            hideDefaultActions: true
        }
    }
];

    options = [
        { label: 'Check-in', value: 'checkin' },
        { label: 'Check-out', value: 'checkout' }

    ];

    handleInputChange(event) {
         const field = event.target.label;
        if (field === 'Permit Search') {
          this.searchTerm = event.target.value;
        }else if (field === 'Process Type') {
           this.selectedValue =event.target.value;
        }
        if(this.selectedValue=='checkout'){
            this.ischeckout=true;
        }
    }
    fetchAuthHeader() {
        fetch('/services/apexrest/headerService/', {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json'
            }
        })
        .then(response => response.json())
        .then(result => {
            console.log('Result: ', result);
        })
        .catch(error => {
            console.error('Error: ', error);
        });
    }

    async handleSearch() {
        if (!this.searchTerm) {
            return;
        }

        this.isLoading = true;
        try {
            const data = await searchRecords({ 
               searchTerm: this.searchTerm,
               loginuserId: this.loginuserId,
               permitType:this.selectedValue
                 });
             this.results = data;
             if (!this.results || this.results.length === 0) {
               this.noResults = true;
             } else {
               this.noResults = false;
             }
            console.log('this.results---'+  JSON.stringify(this.results));
        } catch (error) {
            console.error('Error fetching search results:', error);
        } finally {
            this.isLoading = false;
        }
    }
    handleRowAction(event) { 
    const action = event.detail.action;
    const row = event.detail.row;

     if (action.name === 'edit') {
        this.selectedContactId = row.Id; // Store selected record Id
     }
    }
   

}