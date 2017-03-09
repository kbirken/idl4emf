package org.csu.idl.xtext.loader

import com.google.inject.Injector
import java.io.ByteArrayInputStream
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import org.csu.idl.idlmm.Include
import org.csu.idl.idlmm.TranslationUnit
import org.csu.idl.xtext.IDLStandaloneSetup
import org.csu.idl.xtext.transformation.ArrayExpander
import org.csu.idl.xtext.transformation.ExpressionEvaluator
import org.csu.idl.xtext.transformation.Include2TranslationUnit
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.linking.lazy.LazyLinkingResource
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.resource.XtextResourceSet
import java.io.ByteArrayOutputStream

class ExtendedIDLLoader extends IDLLoader {	
	Injector injector
	
	XtextResourceSet resourceSet

	Map<TranslationUnit, String> map_TranslationUnit_FileName
	
	Map<String, Resource> includesMap2 = new HashMap<String, Resource>();
	Map<String, ArrayList<URI>> dependencies = newHashMap
	
	Map<String, byte[]> resources
	
	new () {
		injector = new IDLStandaloneSetup().createInjectorAndDoEMFRegistration
		resourceSet = injector.getInstance(XtextResourceSet)

		map_TranslationUnit_FileName = newLinkedHashMap()
		
		resources = newLinkedHashMap()
		
		resourceSet.addLoadOption(XtextResource.OPTION_RESOLVE_ALL, Boolean.FALSE);
	}
	
	override load(String filePath) throws Exception {
		// preprocessor gets rid of #ifndef, #define, #endif and recomputes the absolute paths of includes
		preprocessor.run(filePath)
		val streams = preprocessor.streamMap
		for(path : streams.keySet) {
			// correct the processing result
			val raw = streams.get(path).toString
			resources.put(path, raw.replace("\\", "\\\\").bytes)
		}
		
		val uri = URI.createFileURI(filePath)
		val resource = resourceSet.createResource(uri)
		val data = resources.get(filePath)
		val in = new ByteArrayInputStream(data)
		resource.load(in, resourceSet.getLoadOptions())
		
		val trUnit = resource.contents.get(0) as TranslationUnit
		finalize(uri, trUnit)

		Include2TranslationUnit.convertInclude2TranslationUnit(trUnit, this)

		logger.debug("Loaded " + filePath + " as resource " + resource.URI)
	}
	
	override loadInclude(Include include) throws Exception {
		val filePath = include.importURI
		val importURI = URI.createFileURI(filePath)
		
		val owningResource = include.eResource.URI.toString
		var list = dependencies.get(owningResource)
		if (list==null) {
			list = <URI>newArrayList
			dependencies.put(owningResource, list)
		}
		list.add(importURI)
		
		if (includesMap2.containsKey(filePath)) {
			return includesMap2.get(filePath)
		}

		// load the resource
		val resourceSet = include.eResource().resourceSet
		val resource = resourceSet.createResource(importURI)

		logger.debug("Cache fault! Loading " + filePath + " as " + resource.URI)

		// cache
		includesMap2.put(include.importURI, resource)
		val data = resources.get(filePath)
		val in = new ByteArrayInputStream(data)
		resource.load(in, resourceSet.getLoadOptions())
		
		val uri = URI.createFileURI(filePath)
		val trUnit = resource.contents.get(0) as TranslationUnit
		finalize(uri, trUnit)

		logger.debug("Loaded " + filePath + " as resource " + resource.URI)

		return resource;
	}

	def private finalize(URI uri, TranslationUnit trUnit) {
		// compute basename for input file (last segment without extension)
		val last = uri.lastSegment
		val suffix = "." + uri.fileExtension
		val i = last.lastIndexOf(suffix)
		val basename = last.substring(0, i)
		map_TranslationUnit_FileName.put(trUnit, basename)
				
		// transformations
		ExpressionEvaluator.evaluate(trUnit)
		ArrayExpander.expand(trUnit)
	}

	def getModels() {
		return map_TranslationUnit_FileName
	}
	
	def getDependencies() {
		return dependencies
	}
}
