
package org.csu.idl.xtext;

import org.csu.idl.idlmm.IdlmmPackage;
import org.eclipse.emf.ecore.EPackage;

import com.google.inject.Injector;

/**
 * Initialization support for running Xtext languages 
 * without equinox extension registry
 */
public class IDLStandaloneSetup extends IDLStandaloneSetupGenerated{

	public static void doSetup() {
		new IDLStandaloneSetup().createInjectorAndDoEMFRegistration();
	}
	
	@Override
    public void register(Injector injector) {
        if (!EPackage.Registry.INSTANCE.containsKey("http://idlmm/1.0")) {
            EPackage.Registry.INSTANCE.put("http://idlmm/1.0", IdlmmPackage.eINSTANCE);
        }
        super.register(injector);
    }
}

