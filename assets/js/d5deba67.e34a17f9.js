"use strict";(self.webpackChunksuse_edge_docs=self.webpackChunksuse_edge_docs||[]).push([[720],{3905:(e,t,r)=>{r.d(t,{Zo:()=>u,kt:()=>f});var o=r(7294);function i(e,t,r){return t in e?Object.defineProperty(e,t,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[t]=r,e}function n(e,t){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),r.push.apply(r,o)}return r}function a(e){for(var t=1;t<arguments.length;t++){var r=null!=arguments[t]?arguments[t]:{};t%2?n(Object(r),!0).forEach((function(t){i(e,t,r[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):n(Object(r)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(r,t))}))}return e}function s(e,t){if(null==e)return{};var r,o,i=function(e,t){if(null==e)return{};var r,o,i={},n=Object.keys(e);for(o=0;o<n.length;o++)r=n[o],t.indexOf(r)>=0||(i[r]=e[r]);return i}(e,t);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);for(o=0;o<n.length;o++)r=n[o],t.indexOf(r)>=0||Object.prototype.propertyIsEnumerable.call(e,r)&&(i[r]=e[r])}return i}var l=o.createContext({}),c=function(e){var t=o.useContext(l),r=t;return e&&(r="function"==typeof e?e(t):a(a({},t),e)),r},u=function(e){var t=c(e.components);return o.createElement(l.Provider,{value:t},e.children)},d="mdxType",m={inlineCode:"code",wrapper:function(e){var t=e.children;return o.createElement(o.Fragment,{},t)}},p=o.forwardRef((function(e,t){var r=e.components,i=e.mdxType,n=e.originalType,l=e.parentName,u=s(e,["components","mdxType","originalType","parentName"]),d=c(r),p=i,f=d["".concat(l,".").concat(p)]||d[p]||m[p]||n;return r?o.createElement(f,a(a({ref:t},u),{},{components:r})):o.createElement(f,a({ref:t},u))}));function f(e,t){var r=arguments,i=t&&t.mdxType;if("string"==typeof e||i){var n=r.length,a=new Array(n);a[0]=p;var s={};for(var l in t)hasOwnProperty.call(t,l)&&(s[l]=t[l]);s.originalType=e,s[d]="string"==typeof e?e:i,a[1]=s;for(var c=2;c<n;c++)a[c]=r[c];return o.createElement.apply(null,a)}return o.createElement.apply(null,r)}p.displayName="MDXCreateElement"},8133:(e,t,r)=>{r.r(t),r.d(t,{assets:()=>l,contentTitle:()=>a,default:()=>m,frontMatter:()=>n,metadata:()=>s,toc:()=>c});var o=r(7462),i=(r(7294),r(3905));const n={sidebar_position:3,title:"Modify SLE Micro ISO (or any SLE ISO)"},a=void 0,s={unversionedId:"misc/modify-sle-micro-iso",id:"misc/modify-sle-micro-iso",title:"Modify SLE Micro ISO (or any SLE ISO)",description:"This is totally unsupported. Via elemental-iso-add-registration.",source:"@site/docs/misc/modify-sle-micro-iso.md",sourceDirName:"misc",slug:"/misc/modify-sle-micro-iso",permalink:"/docs/misc/modify-sle-micro-iso",draft:!1,editUrl:"https://github.com/suse-edge/suse-edge.github.io/tree/main/docs/misc/modify-sle-micro-iso.md",tags:[],version:"current",lastUpdatedBy:"Eduardo M\xednguez",lastUpdatedAt:1686641845,formattedLastUpdatedAt:"Jun 13, 2023",sidebarPosition:3,frontMatter:{sidebar_position:3,title:"Modify SLE Micro ISO (or any SLE ISO)"},sidebar:"docs",previous:{title:"Rancher portfolio disambiguation",permalink:"/docs/misc/rancher-disambiguation"},next:{title:"Create a package (RPM or Container image) using OBS (openSUSE Build Service)",permalink:"/docs/dev_howto/create-package-obs"}},l={},c=[],u={toc:c},d="wrapper";function m(e){let{components:t,...r}=e;return(0,i.kt)(d,(0,o.Z)({},u,r,{components:t,mdxType:"MDXLayout"}),(0,i.kt)("blockquote",null,(0,i.kt)("p",{parentName:"blockquote"},"\u26a0\ufe0f This is totally unsupported. Via ",(0,i.kt)("a",{parentName:"p",href:"https://github.com/rancher/elemental/blob/c00c34268572572f4bc2131c0121f6d8b5712942/.github/elemental-iso-add-registration#L62"},"elemental-iso-add-registration"),".")),(0,i.kt)("h1",{id:"requisites"},"Requisites"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"SLE Micro ISO (or any SLE ISO)"),(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("a",{parentName:"li",href:"https://www.gnu.org/software/xorriso/"},"xorriso"),". It can be installed with ",(0,i.kt)("a",{parentName:"li",href:"https://software.opensuse.org/package/xorriso"},(0,i.kt)("inlineCode",{parentName:"a"},"zypper"))," or via the ",(0,i.kt)("inlineCode",{parentName:"li"},"registry.opensuse.org/isv/rancher/elemental/stable/teal53/15.4/rancher/elemental-builder-image/5.3:latest")," container image.")),(0,i.kt)("h1",{id:"usage"},"Usage"),(0,i.kt)("p",null,"Imagine you want to modify the ",(0,i.kt)("inlineCode",{parentName:"p"},"/boot/grub2/grub.cfg")," file. You just need to:"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"mount the ISO somewhere")),(0,i.kt)("pre",null,(0,i.kt)("code",{parentName:"pre"},"ISO=${${HOME}/SLE-Micro.x86_64-5.4.0-Default-SelfInstall-GM.install.iso}\nDIR=$(mktemp -d)\nsudo mount ${ISO} ${DIR}\n")),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"extract the file")),(0,i.kt)("pre",null,(0,i.kt)("code",{parentName:"pre"},"cp ${DIR}/boot/grub2/grub.cfg /tmp/mygrub.cfg\n")),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"perform the modifications as needed"),(0,i.kt)("li",{parentName:"ul"},"Umount the ISO (not really needed)")),(0,i.kt)("pre",null,(0,i.kt)("code",{parentName:"pre"},"sudo umount ${DIR}\nrmdir ${DIR} \n")),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"rebuild the ISO as")),(0,i.kt)("pre",null,(0,i.kt)("code",{parentName:"pre"},"xorriso -indev ${ISO} -outdev SLE-Micro-tweaked.iso -map /tmp/mygrub.cfg /boot/grub2/grub.cfg -boot_image any replay\n\nxorriso 1.4.6 : RockRidge filesystem manipulator, libburnia project.\n\nxorriso : NOTE : ISO image bears MBR with  -boot_image any partition_offset=16\nxorriso : NOTE : Loading ISO image tree from LBA 0\nxorriso : UPDATE : 371 nodes read in 1 seconds\nlibisofs: WARNING : Found hidden El-Torito image. Its size could not be figured out, so image modify or boot image patching may lead to bad results.\nxorriso : NOTE : Detected El-Torito boot information which currently is set to be discarded\nDrive current: -indev './SLE-Micro.x86_64-5.4.0-Default-RT-SelfInstall-GM.install.iso'\nMedia current: stdio file, overwriteable\nMedia status : is written , is appendable\nBoot record  : El Torito , MBR grub2-mbr cyl-align-off\nMedia summary: 1 session, 494584 data blocks,  966m data,  114g free\nVolume id    : 'INSTALL'\nDrive current: -outdev 'SLE-Micro-tweaked.iso'\nMedia current: stdio file, overwriteable\nMedia status : is blank\nMedia summary: 0 sessions, 0 data blocks, 0 data,  114g free\nxorriso : UPDATE : 1 files added in 1 seconds\nAdded to ISO image: file '/boot/grub2/grub.cfg'='/tmp/mygrub.cfg'\nxorriso : NOTE : Replayed 21 boot related commands\nxorriso : NOTE : Copying to System Area: 32768 bytes from file '--interval:imported_iso:0s-15s:zero_mbrpt:./SLE-Micro.x86_64-5.4.0-Default-RT-SelfInstall-GM.install.iso'\nxorriso : NOTE : Preserving in ISO image: -boot_image any partition_offset=16\nxorriso : UPDATE : Writing:      32768s    6.5%   fifo 100%  buf  50%\nxorriso : UPDATE : Writing:      67205s   13.3%   fifo  96%  buf  50%\nxorriso : UPDATE : Writing:     442368s   87.6%   fifo 100%  buf  50%  553.8xD\nISO image produced: 504777 sectors\nWritten to medium : 504784 sectors at LBA 48\nWriting to 'SLE-Micro-tweaked.iso' completed successfully.\n")))}m.isMDXComponent=!0}}]);