import { donation_tracker_canister } from "canisters/donation_tracker_canister";

export const calculateCurrencyUnitAddition = (paymentType, amount) => {
  switch(paymentType) {
    case 'BTC':
      return `(equals ${(amount / 100000000.0).toFixed(8)} BTC)`;
      break;
    case 'ckBTC':
      return `(equals ${(amount / 100000000.0).toFixed(8)} ckBTC)`;
      break;
    // Add cases for other supported payment types here
    default:
      return "";
  };
};

export async function submitEmailSignUpForm(emailAddress, pageSubmittedFrom) {
  const input = {
    emailAddress: emailAddress,
    pageSubmittedFrom: pageSubmittedFrom,
  };
  let result = await donation_tracker_canister.submitSignUpForm(input);
  return result;
}

export const supportedImageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.svg'];
export const supportedVideoExtensions = ['.mp4', '.mov'];
export const supported3dModelExtensions = ['.glb', '.gltf'];

export function getNumber(value) {
  return parseFloat(value.toFixed(3));
}

export function getMajorVersion(version) {
  var major = version.split('.');
  var clean = false;
  for (var i = 0; i < major.length; i++) {
    if (clean) {
      major[i] = 0;
    } else if (major[i] !== '0') {
      clean = true;
    }
  }
  return major.join('.');
}

export function equal(var1, var2) {
  var keys1;
  var keys2;
  var type1 = typeof var1;
  var type2 = typeof var2;
  if (type1 !== type2) {
    return false;
  }
  if (type1 !== 'object' || var1 === null || var2 === null) {
    return var1 === var2;
  }
  keys1 = Object.keys(var1);
  keys2 = Object.keys(var2);
  if (keys1.length !== keys2.length) {
    return false;
  }
  for (var i = 0; i < keys1.length; i++) {
    if (!equal(var1[keys1[i]], var2[keys2[i]])) {
      return false;
    }
  }
  return true;
}

export function getOS() {
  var userAgent = window.navigator.userAgent;
  var platform = window.navigator.platform;
  var macosPlatforms = ['Macintosh', 'MacIntel', 'MacPPC', 'Mac68K'];
  var windowsPlatforms = ['Win32', 'Win64', 'Windows', 'WinCE'];
  var iosPlatforms = ['iPhone', 'iPad', 'iPod'];
  var os = null;

  if (macosPlatforms.indexOf(platform) !== -1) {
    os = 'macos';
  } else if (iosPlatforms.indexOf(platform) !== -1) {
    os = 'ios';
  } else if (windowsPlatforms.indexOf(platform) !== -1) {
    os = 'windows';
  } else if (/Android/.test(userAgent)) {
    os = 'android';
  } else if (!os && /Linux/.test(platform)) {
    os = 'linux';
  }

  return os;
}

export function injectCSS(url) {
  var link = document.createElement('link');
  link.href = url;
  link.type = 'text/css';
  link.rel = 'stylesheet';
  link.media = 'screen,print';
  link.setAttribute('data-aframe-inspector', 'style');
  document.head.appendChild(link);
}

export function injectJS(url, onLoad, onError) {
  var link = document.createElement('script');
  link.src = url;
  link.charset = 'utf-8';
  link.setAttribute('data-aframe-inspector', 'style');

  if (onLoad) {
    link.addEventListener('load', onLoad);
  }

  if (onError) {
    link.addEventListener('error', onError);
  }

  document.head.appendChild(link);
}

export function saveString(text, filename, mimeType) {
  saveBlob(new Blob([text], { type: mimeType }), filename);
}

export function saveBlob(blob, filename) {
  var link = document.createElement('a');
  link.style.display = 'none';
  document.body.appendChild(link);
  link.href = URL.createObjectURL(blob);
  link.download = filename || 'ascene.html';
  link.click();
  // URL.revokeObjectURL(url); breaks Firefox...
}

export function registerKeydownEventToExitFullscreen(aScene) {
  aScene.ownerDocument.addEventListener("keydown", function(e) {
    const availableKeys = ["Backspace", "Tab", "Enter", "Escape", "Space", "Home", "MetaLeft", "AltLeft", "AltRight", "ControlLeft", "ControlRight"];
    if (availableKeys.indexOf(e.code) != -1) {
      exitFullscreen();
      exitSceneFullscreen(aScene);
    };
  }, true);
};

export function exitFullscreen() {
  if (document.exitFullscreen) {
    document.exitFullscreen();
  // @ts-ignore
  } else if (document.mozCancelFullScreen) {
    // @ts-ignore
    document.mozCancelFullScreen();
  // @ts-ignore
  } else if (document.webkitExitFullscreen) {
    // @ts-ignore
    document.webkitExitFullscreen();
  };
};

export function exitSceneFullscreen(aScene) {
  if (aScene) {
    try {
      aScene.exitVR();
    } catch (error) {
      console.error("Couldn't exit VR mode");      
    };
    try {
      if (aScene.ownerDocument.exitFullscreen) {
        aScene.ownerDocument.exitFullscreen();
      // @ts-ignore
      } else if (aScene.ownerDocument.mozCancelFullScreen) {
        // @ts-ignore
        aScene.ownerDocument.mozCancelFullScreen();
      // @ts-ignore
      } else if (aScene.ownerDocument.webkitExitFullscreen) {
        // @ts-ignore
        aScene.ownerDocument.webkitExitFullscreen();
      };
    } catch (error) {
      console.error("Couldn't exit fullscreen");      
    };
  };
};
