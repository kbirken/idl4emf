package org.csu.idl.xtext.loader

import com.google.inject.Injector
import java.util.HashMap
import java.util.Map
import org.csu.idl.idlmm.Include
import org.csu.idl.idlmm.TranslationUnit
import org.csu.idl.xtext.IDLStandaloneSetup
import org.csu.idl.xtext.scoping.IDLScopingHelper
import org.csu.idl.xtext.transformation.ArrayExpander
import org.csu.idl.xtext.transformation.ExpressionEvaluator
import org.csu.idl.xtext.transformation.Include2TranslationUnit
import org.csu.idl.xtext.validation.IDLValidator
import org.eclipse.emf.common.util.BasicDiagnostic
import org.eclipse.emf.common.util.Diagnostic
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.linking.lazy.LazyLinkingResource
import org.eclipse.xtext.resource.XtextResourceSet
import java.util.List
import java.io.ByteArrayInputStream

class ExtendedIDLLoader extends IDLLoader {	
	Injector injector
	Map<TranslationUnit, String> map_TranslationUnit_FileName
	XtextResourceSet resourceSet
	int indexInclude
	List<byte[]> resources
	new () {
		map_TranslationUnit_FileName = newLinkedHashMap()
		injector = new IDLStandaloneSetup().createInjectorAndDoEMFRegistration()
		resourceSet = injector.getInstance(XtextResourceSet)
		indexInclude = 0
		resources = newLinkedList()
	}
	
	override load(String filePath) throws Exception {
		// preprocessor gets rid of #ifndef, #define, #endif and recomputes the absolute paths of includes
		preprocessor.run(filePath)
		for (resource: preprocessor.resources) {
			// correct the processing result
			resources.add(resource.toString.replace("\\", "\\\\").bytes)
		}
		IDLScopingHelper.setCurrentLoader(this)
		val resource = resourceSet.createResource(URI.createURI("dummy:/" + indexInclude + "/" + filePath));
		val in = new ByteArrayInputStream(resources.get(indexInclude++))
		resource.load(in, resourceSet.getLoadOptions())
		val uri = URI.createFileURI(filePath)
		map_TranslationUnit_FileName.put((resource as LazyLinkingResource).getContents().get(0) as TranslationUnit, uri.lastSegment.substring(0, uri.lastSegment.indexOf(uri.fileExtension) - 1))
		
		val trunit = (resource.contents.get(0) as TranslationUnit);
				
		var bd = new BasicDiagnostic();
		var idlValidator = new IDLValidator();
		idlValidator.validate(trunit, bd, new HashMap<Object,Object>());
		new ShowErrors().show(bd);
		
		if (bd.getSeverity() == Diagnostic.ERROR)
			System.exit(-1);
		
		// Transformations
		ExpressionEvaluator.evaluate(trunit);
		ArrayExpander.expand(trunit);
		Include2TranslationUnit.convertInclude2TranslationUnit(trunit);

		logger.debug("Loaded " + filePath + " as resource " + resource.getURI());
	}
	
	override loadInclude(Include include) throws Exception {
		val filePath = include.importURI
		if (includesMap.containsKey(include)) {
			logger.debug("Cache hit for " + filePath + "!")
			return includesMap.get(include)
		}

		// load the resource
		val resourceSet = include.eResource().getResourceSet()
		val resource = resourceSet.createResource(URI.createURI("dummy:/" + indexInclude + "/" + filePath))

		logger.debug("Cache fault! Loading " + filePath + " as " + resource.getURI())

		// cache
		includesMap.put(include, resource)
		val in = new ByteArrayInputStream(resources.get(indexInclude++));
		resource.load(in, resourceSet.getLoadOptions());
		val uri = URI.createFileURI(filePath)
		map_TranslationUnit_FileName.put((resource as LazyLinkingResource).getContents().get(0) as TranslationUnit, uri.lastSegment.substring(0, uri.lastSegment.indexOf(uri.fileExtension) - 1))
		
		// Transformations
		val trunit = (resource.contents.get(0) as TranslationUnit)
		ExpressionEvaluator.evaluate(trunit)
		ArrayExpander.expand(trunit)

		logger.debug("Loaded " + filePath + " as resource " + resource.getURI())

		return resource;
	}
	
	def getModels() {
		return map_TranslationUnit_FileName
	}
	
	/**
	 * Return the directory of the given {@code filePath}  
	 */
	private def static getDirectory(String filePath) {
		return URI.createFileURI(filePath.substring(0,filePath.toString.lastIndexOf('\\')));
	}
}