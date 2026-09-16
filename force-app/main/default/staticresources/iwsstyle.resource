.container-wde{
    display: flex;
    flex-direction: column;
}
.logs{
    list-style: none;
    overflow: auto;
    _height: 139px;
    height: 0px;
}
.buttons{
    height: 25px;
    clear:both;
    border-bottom : 1px solid #118AD3;
}
.buttons button{
    margin-left:20px;
}
.buttons label{
    font-size:10px;
}
.logs ul{
    list-style: none;
    padding:0px;
    margin:0px;
}

.version{
    font-size: 10px;
    font-style: italic;
    margin-left: 5px;
    color: #7c7c7c;
}
.title{
    margin: 0 0 0 5px;
    text-align: center;
    font-weight: 700;
    line-height: 18px;
}
.logs ul li{
    padding:4px;
    border:1px solid #118AD3;
    box-sizing: border-box;
    border-top:none;
    margin:0px;
    font-size:10px;
}

.logs ul li p {
    word-wrap: break-word;
    margin:0px;
}

.logs ul li:nth-child(odd) {
    background-color: #CFE7F6;
 }

.header {
    height: 30px;
    border-bottom : 1px solid #118AD3;
    display: flex;
    align-items: center;
    justify-content: center;

  }

  .header img{
      width:40px;
  }

.led-msg{
    height:30px;
    padding:4px;
    border-bottom : 1px solid #118AD3;

}
.led-msg button{
    _float:right;
}

.led-msg p {
    float: left;
    margin: 0 0 0 5px;
    line-height: 16px;
    width: 260px;
    height: 32px;
    overflow: auto;
    font-size: 12px;
    word-wrap: break-word;
}
.btn-logs{
    float:right;
    width:55px;
}

.btn-logs label{
    margin-right:5px;
    font-size:10px;

}
  
  .led-red {
    float: left;
    margin: 0 auto;
    width: 14px;
    height: 14px;
    background-color: #F00;
    border-radius: 50%;
    box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #441313 0 -1px 9px, rgba(255, 0, 0, 0.5) 0 2px 12px;
    -webkit-animation: blinkRed 0.5s infinite;
    -moz-animation: blinkRed 0.5s infinite;
    -ms-animation: blinkRed 0.5s infinite;
    -o-animation: blinkRed 0.5s infinite;
    animation: blinkRed 0.5s infinite;
  }
  
  @-webkit-keyframes blinkRed {
      from { background-color: #F00; }
      50% { background-color: #A00; box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #441313 0 -1px 9px, rgba(255, 0, 0, 0.5) 0 2px 0;}
      to { background-color: #F00; }
  }
  @-moz-keyframes blinkRed {
      from { background-color: #F00; }
      50% { background-color: #A00; box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #441313 0 -1px 9px, rgba(255, 0, 0, 0.5) 0 2px 0;}
      to { background-color: #F00; }
  }
  @-ms-keyframes blinkRed {
      from { background-color: #F00; }
      50% { background-color: #A00; box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #441313 0 -1px 9px, rgba(255, 0, 0, 0.5) 0 2px 0;}
      to { background-color: #F00; }
  }
  @-o-keyframes blinkRed {
      from { background-color: #F00; }
      50% { background-color: #A00; box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #441313 0 -1px 9px, rgba(255, 0, 0, 0.5) 0 2px 0;}
      to { background-color: #F00; }
  }
  @keyframes blinkRed {
      from { background-color: #F00; }
      50% { background-color: #A00; box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #441313 0 -1px 9px, rgba(255, 0, 0, 0.5) 0 2px 0;}
      to { background-color: #F00; }
  }

  .led-yellow {
    float: left;
    
    margin: 0 auto;
    width: 14px;
    height: 14px;
    background-color: #FF0;
    border-radius: 50%;
    box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #808002 0 -1px 9px, #FF0 0 2px 12px;
    -webkit-animation: blinkYellow 1s infinite;
    -moz-animation: blinkYellow 1s infinite;
    -ms-animation: blinkYellow 1s infinite;
    -o-animation: blinkYellow 1s infinite;
    animation: blinkYellow 1s infinite;
  }
  
  @-webkit-keyframes blinkYellow {
      from { background-color: #FF0; }
      50% { background-color: #AA0; box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #808002 0 -1px 9px, #FF0 0 2px 0; }
      to { background-color: #FF0; }
  }
  @-moz-keyframes blinkYellow {
      from { background-color: #FF0; }
      50% { background-color: #AA0; box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #808002 0 -1px 9px, #FF0 0 2px 0; }
      to { background-color: #FF0; }
  }
  @-ms-keyframes blinkYellow {
      from { background-color: #FF0; }
      50% { background-color: #AA0; box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #808002 0 -1px 9px, #FF0 0 2px 0; }
      to { background-color: #FF0; }
  }
  @-o-keyframes blinkYellow {
      from { background-color: #FF0; }
      50% { background-color: #AA0; box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #808002 0 -1px 9px, #FF0 0 2px 0; }
      to { background-color: #FF0; }
  }
  @keyframes blinkYellow {
      from { background-color: #FF0; }
      50% { background-color: #AA0; box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #808002 0 -1px 9px, #FF0 0 2px 0; }
      to { background-color: #FF0; }
  }
  
  .led-green {
    float:left;
    margin: 0 auto;
    width: 14px;
    height: 14px;
    background-color: #008000;
    border-radius: 50%;
    box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #329932 0 -1px 9px, #66b266 0 2px 12px;
  }

  .softphone_content{
    width:348px;
    height:450px;
} 

#pefwidget #pureFrame{
	height: 450px;    
}

body{
    margin:0;
    padding:0;
}
.MuiAccordionSummary-content.Mui-expanded{
    margin:0px;
}

.record .item{
        padding: 2px;
    font-size: 12px;
}
  