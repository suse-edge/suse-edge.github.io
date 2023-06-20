"use strict";(self.webpackChunksuse_edge_docs=self.webpackChunksuse_edge_docs||[]).push([[378],{3905:(e,t,n)=>{n.d(t,{Zo:()=>p,kt:()=>f});var r=n(7294);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function o(e,t){if(null==e)return{};var n,r,a=function(e,t){if(null==e)return{};var n,r,a={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var u=r.createContext({}),c=function(e){var t=r.useContext(u),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},p=function(e){var t=c(e.components);return r.createElement(u.Provider,{value:t},e.children)},s="mdxType",d={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},m=r.forwardRef((function(e,t){var n=e.components,a=e.mdxType,i=e.originalType,u=e.parentName,p=o(e,["components","mdxType","originalType","parentName"]),s=c(n),m=a,f=s["".concat(u,".").concat(m)]||s[m]||d[m]||i;return n?r.createElement(f,l(l({ref:t},p),{},{components:n})):r.createElement(f,l({ref:t},p))}));function f(e,t){var n=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var i=n.length,l=new Array(i);l[0]=m;var o={};for(var u in t)hasOwnProperty.call(t,u)&&(o[u]=t[u]);o.originalType=e,o[s]="string"==typeof e?e:a,l[1]=o;for(var c=2;c<i;c++)l[c]=n[c];return r.createElement.apply(null,l)}return r.createElement.apply(null,n)}m.displayName="MDXCreateElement"},1079:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>u,contentTitle:()=>l,default:()=>d,frontMatter:()=>i,metadata:()=>o,toc:()=>c});var r=n(7462),a=(n(7294),n(3905));const i={sidebar_position:1,title:"*Draft* Introduction"},l="*DRAFT - SUSE Adaptive Telco Infrastructure Platform (ATIP)",o={unversionedId:"product/atip/introduction",id:"product/atip/introduction",title:"*Draft* Introduction",description:"SUSE ATIP is a platform designed for hosting modern, cloud native, Telco applications at scale from core to edge.",source:"@site/docs/product/atip/introduction.md",sourceDirName:"product/atip",slug:"/product/atip/introduction",permalink:"/docs/product/atip/introduction",draft:!1,editUrl:"https://github.com/suse-edge/suse-edge.github.io/tree/main/docs/product/atip/introduction.md",tags:[],version:"current",lastUpdatedBy:"Kristian Zhelyazkov",lastUpdatedAt:1687273028,formattedLastUpdatedAt:"Jun 20, 2023",sidebarPosition:1,frontMatter:{sidebar_position:1,title:"*Draft* Introduction"},sidebar:"docs",previous:{title:"Create a package (RPM or Container image) using OBS (openSUSE Build Service)",permalink:"/docs/dev_howto/create-package-obs"},next:{title:"*Draft* Architecture and Concepts",permalink:"/docs/product/atip/architecture"}},u={},c=[{value:"TL;DR",id:"tldr",level:2},{value:"Contents",id:"contents",level:2}],p={toc:c},s="wrapper";function d(e){let{components:t,...n}=e;return(0,a.kt)(s,(0,r.Z)({},p,n,{components:t,mdxType:"MDXLayout"}),(0,a.kt)("h1",{id:"draft---suse-adaptive-telco-infrastructure-platform-atip"},"*DRAFT - SUSE Adaptive Telco Infrastructure Platform (ATIP)"),(0,a.kt)("p",null,"SUSE ATIP is a platform designed for hosting modern, cloud native, Telco applications at scale from core to edge. "),(0,a.kt)("p",null,"This is the home of ATIP Documentation. This documentation is currently in ",(0,a.kt)("strong",{parentName:"p"},(0,a.kt)("em",{parentName:"strong"},"Draft state and used at your own risk"))),(0,a.kt)("hr",null),(0,a.kt)("h2",{id:"tldr"},"TL;DR"),(0,a.kt)("p",null,"ATIP Comprises multiple components including SLE Micro, RKE2, Rancher and others. This documentation will provide instructions on their installation, configuration and lifecycle management"),(0,a.kt)("h2",{id:"contents"},"Contents"),(0,a.kt)("p",null,"Architecture and Concepts"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"ATIP Architecture"),(0,a.kt)("li",{parentName:"ul"},"Components"),(0,a.kt)("li",{parentName:"ul"},"Example deployment flows")),(0,a.kt)("p",null,"Pre-requisites  "),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Hardware"),(0,a.kt)("li",{parentName:"ul"},"Network"),(0,a.kt)("li",{parentName:"ul"},"Services (DHCP, DNS, etc)")),(0,a.kt)("p",null,"Management Cluster Installation"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"OS Install"),(0,a.kt)("li",{parentName:"ul"},"RKE Install"),(0,a.kt)("li",{parentName:"ul"},"Rancher Install"),(0,a.kt)("li",{parentName:"ul"},"Initial Configuration"),(0,a.kt)("li",{parentName:"ul"},"Bare Metal Management Configuration")),(0,a.kt)("p",null,"Edge Site Installation"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Edge site definition"),(0,a.kt)("li",{parentName:"ul"},"Installation process"),(0,a.kt)("li",{parentName:"ul"},"Cluster Commissioning")),(0,a.kt)("p",null,"Feature Configuration"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Real Time"),(0,a.kt)("li",{parentName:"ul"},"Multus"),(0,a.kt)("li",{parentName:"ul"},"SRIOV"),(0,a.kt)("li",{parentName:"ul"},"DPDK"),(0,a.kt)("li",{parentName:"ul"},"Huge Pages"),(0,a.kt)("li",{parentName:"ul"},"CPU Pinning"),(0,a.kt)("li",{parentName:"ul"},"NUMA Aware scheduling"),(0,a.kt)("li",{parentName:"ul"},"Metal LB (Beta)")),(0,a.kt)("p",null,"Lifecycle Actions"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Software lifecycles"),(0,a.kt)("li",{parentName:"ul"},"Management Cluster upgrades"),(0,a.kt)("li",{parentName:"ul"},"Rancher Upgrades"),(0,a.kt)("li",{parentName:"ul"},"Operating system upgrades"),(0,a.kt)("li",{parentName:"ul"},"RKE2 Upgrades")))}d.isMDXComponent=!0}}]);