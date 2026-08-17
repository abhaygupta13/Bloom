import { LightningElement, track, api, wire } from 'lwc';
import imageDisplayList from '@salesforce/apex/customImageCarouselHandler.getImages';
export default class CustomImageCarousel extends LightningElement {
    @api recordId;
    @track files = []; // Initialize files as an empty array
    @track fullScreen = false;
    sliderData = []; // Initialize sliderData as an empty array
    @track showerror=false;


    @wire(imageDisplayList, { recordId: '$recordId' })
    wiredAccounts({ error, data }) {
        if (data) {
            for (let i = 0; i < data.length; i++) {
                this.files.push('/sfc/servlet.shepherd/version/download/' + data[i]['Id']);
            }
            // Once the files are fetched, set the slider data
            this.sliderData = this.files.map((imageUrl, index) => ({
                image: imageUrl,
                link: '#',
                index: index + 1,
                heading: `Slider ${index + 1}`,
                description: `Slider ${index + 1} description`,
            }));
            if(this.sliderData==''){
              
                this.showerror= true;
            }
        } else if (error) {
            this.error = error;
        }
    }
    getSliderData() {
        return this.sliderData;
    }
    imageExpandHandler() {

        this.fullScreen = true;

    }
    closeImageHandler() {
        this.fullScreen = false;
    }

}